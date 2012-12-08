#!/usr/bin/env python

import sys,os


fin = "font.in"
fon = "font_hor.c"


with open(fon, 'w') as fo:
  fo.write(     "/* font_hor.c */\n\n")
  fo.write(     "const char font_hor [][] = {\n")
  with open(fin, 'r') as fi:
    for line in fi.readlines():
      fo.write( "  {%s},\n" % line.strip().replace("$", "0x").replace(",", ", "))
  fo.write(     "};\n\n")

