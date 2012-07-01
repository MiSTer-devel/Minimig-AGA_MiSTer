#!/usr/bin/env python
# unhexer.py
# decode a word-size intel-hex file
#
# usage: unhexer.py <in.hex> <out.bin>

from optparse import OptionParser

# parse args
parser = OptionParser("usage: %prog [options] <in.bin> <out.hex>")
parser.add_option('-s', "--start", dest="start", help="start address of output", action="store", type=int, default=0)
parser.add_option('-l', "--length", dest="length", help="total length of output binary", action="store", type=int, default=0)
(options, args) = parser.parse_args()
if len(args) != 2:
    parser.error("incorrect number of arguments")
in_hex = args[0]
out_bin = args[1]
    
# read input file
data = ""
f = open(in_hex,"r")
for line in f:
    if line[0:3] == ':02':
        val = line[9:13]
        hi = int(val[0:2],16)
        lo = int(val[2:4],16)
        data += chr(hi) + chr(lo)
f.close()
print len(data)

# write output file
f = open(out_bin,"wb")
f.write(data)
f.close()

