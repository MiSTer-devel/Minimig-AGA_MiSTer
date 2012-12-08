#!/usr/bin/env python

import sys,os
from PIL import Image


fin = "Minimig2OnBlue_edit.png"
fon = "boot_logo.c"

fi = Image.open(fin)
di = fi.getdata()

src_w = fi.size[0]
src_h = fi.size[1]

if (src_w % 8):
  sys.stderr.write("Input image width not a multiple of 8 pixels.\n")
  sys.exit(-1)

with open(fon, 'w') as fo:
  fo.write(     "/* %s */\n\n" % fon)
  fo.write(     "const unsigned int logo_width  = %s;\n" % (src_w/8))
  fo.write(     "const unsigned int logo_height = %d;\n" % src_h)
  fo.write(     "\n")
  fo.write(     "const char boot_logo[][] = {\n")
  for h in range(src_h):
    fo.write(   "  { ")
    for w in range(0,src_w,8):
      d = 0
      for p in range (8):
        d = d<<1 | (fi.getpixel((w+p,h)) & 0x1)
      fo.write( "0x%02x, " % d)
    fo.seek(-2,1)
    fo.write(   " },\n")
  fo.seek(-2,1)
  fo.write(     "\n};\n\n")

