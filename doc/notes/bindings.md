# BindGroups and Bindings
Bindgroups let you say "These are my mesh bindings",
rather than "this is my mesh texture, this is my mesh sampler, this is my mesh color", etc

The best strategy is group and order them by frequency of change.
0. Global bindings that never change
1. Per Model bindings. Data shared by all meshes in a model.
2. Per Mesh bindings
  - Textures / Samplers
  - Color Tint
  - ...
3. Multiple times per mesh
Group 0 changes less than 1, which changes less than 2, etc
The spec only guarantees 4 bind groups at minimum (lowest mobile HW tier),
so doing one binding per group would be very restrictive.

You group them because they tend to be made and changed together at the same time, like my example with globals vs mesh data.
Mesh data might have some textures, a sampler, a color tint, etc
They're likely all going to be made at the same time, and changed at the same time
So each one of those uniforms becomes part of a single group, and have their own binding index into that group


## Clarify
It's about how often the bindings change than how often the data changes.
Meaning how often you bind a group to an index.

If you have a uniform buffer that you write to every frame,
but all draw calls use the same buffer during that frame,
the buffer should go into the "global" group, because you only set this bind group once per frame.

On the other hand, if you have multiple meshes and each of them has its own texture,
you would create a bind group for each mesh (all with the same layout you define for the "mesh" bind group).
When you render a frame, you would change the bind group bound to index 2 ("mesh") for every mesh you draw.

