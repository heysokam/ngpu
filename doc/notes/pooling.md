# Resource Pooling
https://learn.unity.com/tutorial/introduction-to-object-pooling
https://en.wikipedia.org/wiki/Object_pool_pattern
These comments provide a pretty decent overview of how it's handled in Sokol
https://github.com/floooh/sokol/blob/master/sokol_gfx.h#L353-L384
https://github.com/floooh/sokol/blob/master/sokol_gfx.h#L820-L974
It's just pre-allocating collections of resources up front
and then using indices from those collections as IDs to refer to the resources
This is where this is done in this library:
https://github.com/floooh/sokol/blob/master/sokol_gfx.h#L15283
Another optimization you could make is:
https://realtimecollisiondetection.net/blog/?p=86

g: There's a couple of reasons - first of all to prevent resource exhaustion. The various graphics APIs only allow for a certain number of resources to be allocated so if you have code that is constantly instantiating GPU resources you could run into nasty errors.
   Another reason is simply performance - if you do all your resource allocation up front, then you don't have to allocate / re-allocate resources during the lifecycle of your program
   It's similar to object pooling - a design pattern that's used pretty heavily in game dev
   To break down how it works - basically you allocate a pool of resources at the start of your application lifecycle. When the user requests a resource, you check the length of the list of used resources - so it'd start with 0 (this is simply an index to lookup a resource from the list)
   you have some way of denoting the resources as being used and when a user is done with a resource it is returned to the pool for re-use

s: that very much sounds like an engine feature, not a renderer one
   but again, i don't understand it, so ignore me if im being noob
g: Well most popular graphics libraries do this - BGFX, Sokol, etc...
   even some of the wgpu-native examples do this
   if you're just creating bindings to the API that's one thing, but this is an optimization that any user of your bindings is going to want to have at their disposal

s: shouldn't a renderer just have a way to say "here, draw this in this way", and that's it? what am i missing? 
g: I mean - wrapping WGPU doesn't give you a renderer
   it just gives you a graphics API
   a renderer is a higher level abstraction built on top of a graphics API

s: definitely not a wgpu bindings feature, then
   i plan on keeping the bindings as they are, just like the official opengl ones
   i plan on making an abstraction on top, but it wont be in the bindings
g: resource pooling is what you'd want to stick in the abstraction. along with any other optimizations

