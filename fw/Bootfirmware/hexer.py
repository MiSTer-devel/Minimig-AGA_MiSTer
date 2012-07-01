#!/usr/bin/env python
# hexer.py
# create a word-size intel-hex file
#
# usage: hexer.py <in.bin> <out.hex>

from optparse import OptionParser

# parse args
parser = OptionParser("usage: %prog [options] <in.bin> <out.hex>")
parser.add_option('-s', "--start", dest="start", help="start address of output", action="store", type=int, default=0)
parser.add_option('-l', "--length", dest="length", help="total length of output binary", action="store", type=int, default=0)
(options, args) = parser.parse_args()
if len(args) != 2:
    parser.error("incorrect number of arguments")
in_bin = args[0]
out_hex = args[1]
    
# read input file
f = open(in_bin,"rb")
data = f.read()
f.close()
data_len = len(data)
print "hexer: input has %d bytes" % data_len

# pad input file
if options.length > 0 and data_len < options.length:
    pad_len = options.length - data_len
    pad = "\xff" * pad_len
    data += pad
    data_len = options.length
    print "hexer: padded to %d bytes" % data_len

# create intel hex
num_words = data_len / 2
pos = 0
addr = options.start
f = open(out_hex,"w")
for i in xrange(num_words):
    addr_hi = addr >> 8
    addr_lo = addr & 0xff
    bytes = [ 2, addr_hi, addr_lo, 0, ord(data[pos]), ord(data[pos+1]) ]
    pos += 2
    addr += 1
    chk = 0
    for b in bytes:
        chk += b
    chk = (~chk + 1) & 0xff
    bytes.append(chk)
    line = ":" + "".join(map(lambda x : "%02X" % x, bytes)) + "\r\n"
    f.write(line)
f.write(":00000001FF\r\n")
f.close()
