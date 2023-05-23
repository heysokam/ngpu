
Might be loaded with:
Features::TEXTURE_BINDING_ARRAY | Features::PARTIALLY_BOUND_BINDING_ARRAY
https://wgpu.rs/doc/wgpu/struct.Features.html
then you'll have to use count in BindGroupLayoutEntry

there's another feature for non-uniform indexing
