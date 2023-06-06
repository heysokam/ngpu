#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# std dependencies
import std/strformat
# External dependencies
import wgpu
# ndk dependencies
import nstd
# ngpu dependencies
import ../types as ngpu
import ../tool/logger
import ./bindings
import ./validate


##[ TODO: Customizable properties
# Texture
sampler.typ           : SamplerBindingType.nonFiltering,  # Set filter to none for Textures
texture.sampleType    : TextureSampleType.Float,          # Set the color type to float
texture.viewDimension : TextureViewDimension.dim2D,       # Make it a 2D texture
texture.multisampled  : false,
]##


#_____________________________
# Texture: Validate
#__________________
proc hasBinding *(src :TexData | ngpu.Sampler) :bool=  not src.binding.empty
  ## Checks that the given TexData or Sampler object has a correct binding initialized.
proc hasBinding *(tex :ngpu.Texture) :bool=  not tex.data.binding.empty and not tex.data.binding.empty
  ## Checks that both the data and sampler of the given Texture object have a correct binding initialized.
proc hasCode *(src :TexData | ngpu.Sampler) :bool=  src.code.hasCode
  ## Checks if the code of the given TexData or Sampler object has been initialized.
  ## Code is considered uninitialized if at least one of the fields is empty.
proc hasCode *(tex :ngpu.Texture) :bool=  tex.data.code.hasCode and tex.sampl.code.hasCode
  ## Checks if the code for both the data and sampler of the given Texture object have been initialized.
  ## Code is considered uninitialized if at least one of the fields is empty.
proc registered *(src :TexData | ngpu.Sampler) :bool=  src.hasBinding and src.hasCode
  ## Returns true if the given TexData or Sampler object has already been registered.
proc registered *(tex :ngpu.Texture) :bool=  tex.data.hasBinding and tex.sampl.hasBinding and tex.data.hasCode and tex.sampl.hasCode
  ## Returns true if both the data and Sampler of the given Texture object have already been registered.


#_______________________________________
# Management
#___________________
proc initBinding *(tex :var TexData;
    gid   : Group;
    bid   : BindingID;
    usage : ShaderStageFlags = { ShaderStage.fragment };
  ) :void=
  ## Inititializes the Binding of the given Texture object.
  ## When omitted, usage will be for the fragment stage only.
  tex.binding       = new Bind
  tex.binding.group = gid
  tex.binding.id    = bid
  tex.binding.kind  = BindingKind.tex
  tex.binding.shape = BindingShape.new(
    T      = tex.type,
    bindID = tex.binding.id,
    kind   = tex.binding.kind,
    usage  = usage,
    label  = tex.label&" BindingShape Entry"
    ) # << BindingShape.new( ... )
  tex.binding.ct = Binding.new(
    tex  = tex,
    id   = tex.binding.id,
    ) # << Binding.new( ... )
#___________________
proc initBinding *(sampler :var ngpu.Sampler;
    gid   : Group;
    bid   : BindingID;
    usage : ShaderStageFlags = { ShaderStage.fragment };
  ) :void=
  ## Inititializes the Binding of the given Sampler object.
  ## When omitted, usage will be for the fragment stage only.
  sampler.binding       = new Bind
  sampler.binding.group = gid
  sampler.binding.id    = bid
  sampler.binding.kind  = BindingKind.sampler
  sampler.binding.shape = BindingShape.new(
    T      = sampler.type,
    bindID = sampler.binding.id,
    kind   = sampler.binding.kind,
    usage  = usage,
    label  = sampler.label&" BindingShape Entry"
    ) # << BindingShape.new( ... )
  sampler.binding.ct = Binding.new(
    sampler = sampler,
    id      = sampler.binding.id,
    ) # << Binding.new( ... )
#___________________
proc initBinding *(tex :var ngpu.Texture;
    gid   : Group;
    bid   : BindingID;
    usage : ShaderStageFlags = { ShaderStage.fragment };
  ) :void=
  ## Inititializes the Binding of both the data and sampler of the given Texture object.
  ## When omitted, usage will be for the fragment stage only.
  tex.data.initBinding(  gid, bid,   usage )
  tex.sampl.initBinding( gid, bid+1, usage )

#___________________
proc upload *(device :ngpu.Device; tex :TexData) :void=
  ## Queues an upload operation to copy the given texture data to the GPU.
  # Create the Texture Copy arguments
  var destination = ImageCopyTexture(
    nextInChain : nil,
    texture     : tex.ct,
    mipLevel    : 0,
    origin      : Origin3D(x:0, y:0, z:0),
    aspect      : TextureAspect.all,
    ) # << ImageCopyTexture( ... )
  # Create the Texture Shape
  var source = TextureDataLayout(
    nextInChain  : nil,
    offset       : 0,
    bytesPerRow  : sizeof(tex.img.data[0].type).uint32 * tex.img.width.uint32,
    rowsPerImage : tex.img.height.uint32,
    ) # << TextureDataLayout( ... )
  # Upload the texture to the GPU
  device.queue.ct.write(
    destination = destination.addr,
    data        = tex.img.data[0].addr,
    dataSize    = tex.img.data.size.csize_t,
    dataLayout  = source.addr,
    writeSize   = tex.cfg.size.addr,
    ) # << queue.writeTexture( ... )
#___________________
proc upload *(device :ngpu.Device; tex :ngpu.Texture) :void=
  ## Queues an upload operation to copy the data of the given texture to the GPU.
  device.upload(tex.data)


#_______________________________________
# Constructors
#__________________
proc new *(_:typedesc[ngpu.TexView];
    tex   : wgpu.Texture;
    cfg   : wgpu.TextureDescriptor;
    label : str = "ngpu | Texture View";
  ) :TexView=
  new result
  result.label = label
  result.cfg   = TextureViewDescriptor(
    nextInChain     : nil,
    label           : result.label.cstring,
    format          : cfg.format,
    dimension       : cfg.dimension,
    baseMipLevel    : 0,
    mipLevelCount   : cfg.mipLevelCount,
    baseArrayLayer  : 0,
    arrayLayerCount : cfg.size.depthOrArrayLayers,
    aspect          : TextureAspect.all,
    ) # << TextureViewDescriptor( ... )
  result.ct = tex.create(result.cfg.addr)  # texture.createTextureView()
#__________________
proc new *(_:typedesc[TexData];
    img     : Image;
    varName : str;
    device  : ngpu.Device;
    upload  : bool = false;
    label   : str  = "ngpu | Texture";
  ) :TexData=
  new result
  result.label = label
  result.img   = img
  result.code  = BindCode(vName: varName)  # init with empty code, until registered
  result.cfg   = TextureDescriptor(
    nextInChain          : nil,
    label                : result.label.cstring,
    usage                : { TextureUsage.copyDst, TextureUsage.textureBinding },
    dimension            : TextureDimension.dim2D,
    size                 : Extent3D(
      width              : result.img.width.uint32,
      height             : result.img.height.uint32,
      depthOrArrayLayers : 1,
      ), # << size
    format               : TextureFormat.RGBA8Unorm,  # Might want:  RGBA8Unorm, RGBA8UnormSrgb
    mipLevelCount        : 1,
    sampleCount          : 1,
    viewFormatCount      : 0,
    viewFormats          : nil,
    ) # << device.createTexture()
  result.ct   = device.ct.create(result.cfg.addr)
  result.view = ngpu.TexView.new(
    tex   = result.ct,
    cfg   = result.cfg,
    label = result.label&" View"
    ) # << TextureView.new( ... )
  # Require post-initialization of the binding
  result.binding = nil
  # Only upload when specified
  if upload: device.upload(result)
#___________________
proc new *(_:typedesc[ngpu.Sampler];
    device  : ngpu.Device;
    varName : str;
    wrap    : Wrap   = Wrap.default();
    filter  : Filter = Filter.default();
    label   : str    = "ngpu | Sampler";
  ) :ngpu.Sampler=
  new result
  result.label = label
  result.code  = BindCode(vName: varName)  # init with empty code, until registered
  result.cfg   = SamplerDescriptor(
    nextInChain   : nil,
    label         : result.label.cstring,
    addressModeU  : wrap.u,
    addressModeV  : wrap.v,
    addressModeW  : wrap.w,
    magFilter     : filter.mag,
    minFilter     : filter.Min,
    mipmapFilter  : filter.mip,
    lodMinClamp   : filter.lod.Min.cfloat,
    lodMaxClamp   : filter.lod.Max.cfloat,
    compare       : CompareFunction.undefined,
    maxAnisotropy : filter.ani,
    ) # << SamplerDescriptor( ... )
  result.ct = device.ct.create(result.cfg.addr)
  # Require post-initialization of the binding
  result.binding = nil
#___________________
proc new *(_:typedesc[ngpu.Texture];
    img         : Image;
    device      : ngpu.Device;
    textureName : str;
    samplerName : str    = "";
    wrap        : Wrap   = Wrap.default();
    filter      : Filter = Filter.default();
    upload      : bool   = false;
    label       : str    = "ngpu | Texture";
  ) :ngpu.Texture=
  ## Creates a new sampled Texture, by creating its data and sampler with the given inputs.
  ## samplerName will be `textureName`Sampler when omitted.
  new result
  result.data = TexData.new(
    img     = img,
    varName = textureName,
    device  = device,
    upload  = upload,
    label   = label&" Data",
    ) # << TexData.new( ... )
  result.sampl = ngpu.Sampler.new(
    device  = device,
    varName = if samplerName == "": textureName&"Sampler" else: samplerName,
    wrap    = wrap,
    filter  = filter,
    label   = label&" Sampler",
    ) # << Sampler.new( ... )


#_____________________________
# Code Generation
#__________________
proc genCode *(src :TexData | ngpu.Sampler) :BindCode=
  ## Generates the code for the given TexData object, and returns it as a BindCode object.
  ## The input object is not modified.
  ## WRN: Expects src.code to already contain a vName.
  assert src.code.vName != "", "Tried to generate code for a TexData or Sampler object, but its vName field is empty."
  assert src.binding != nil,   "Tried to generate code for a TexData or Sampler object, but its binding is not initialized."
  result = BindCode.new(
    data    = src,
    varName = src.code.vName,
    groupID = src.binding.group,
    bindID  = src.binding.id,
    ) # << BindCode.new( ... )
#___________________
proc genCode *(src :ngpu.Texture) :tuple[data:BindCode, sampl:BindCode]=
  ## Generates the code for both the data and sampler of the given TexData object, and returns it as a tuple of BindCode objects.
  ## The contents of the input object are not modified.
  ## WRN: Expects both src.data.code and src.sampl.code to already contain a vName.
  result = (
    data      : BindCode.new(
      data    = src.data,
      varName = src.data.code.vName,
      groupID = src.data.binding.group,
      bindID  = src.data.binding.id,
      ), # << BindCode.new( ... )
    sampl     : BindCode.new(
      data    = src.sampl,
      varName = src.sampl.code.vName,
      groupID = src.sampl.binding.group,
      bindID  = src.sampl.binding.id,
      ) # << BindCode.new( ... )
    ) # << result( ... )

#___________________
proc initCode *(src :var TexData | var ngpu.Sampler) :void=
  ## Initializes the code field for the given TexData or Sampler object.
  if src.hasCode: wrn "Generating shader code for a TexData object that already has it."
  src.code = src.genCode()
proc initCode *(src :var ngpu.Texture) :void=
  ## Initializes the code fields for both TexData and Sampler of the given Texture object.
  src.data.initCode()
  src.sampl.initCode()

#___________________
proc getCode *(src :TexData | ngpu.Sampler) :string=  src.code.variable
  ## Returns the block of wgsl code for the given TexData or Sampler object.
proc getCode *(tex :ngpu.Texture) :string=  tex.data.getCode & tex.sampl.getCode
  ## Returns the block of wgsl code for the given TexData or Sampler object.

