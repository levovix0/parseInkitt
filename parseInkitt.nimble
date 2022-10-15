version       = "0.1.0"
author        = "levovix0"
description   = "Inkitt books parser and translator"
license       = "MIT"
srcDir        = "src"
bin           = @["parseInkitt"]

requires "nim >= 1.4.8"
requires "fusion", "cligen", "nimpy", "chronos"
