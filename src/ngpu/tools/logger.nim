#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# TODO
# template log  *(msg :varargs[string, `$`]) :void=
  # for it in msg: debugEcho(msg)
const log  * = debugEcho
const info * = log
const wrn  * = log
const err  * = log
const fail * = log

