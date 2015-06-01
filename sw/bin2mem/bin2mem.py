#!/usr/bin/env python


"""
Parses a binary file, optionally padds it, and outputs in hexadecimal format
for use in either Verilog $readmemh function (.hex) or
Altera memory initialization format (.mif).
"""


################################################################################
## imports
################################################################################
from __future__ import with_statement
import sys, os, math
from optparse import OptionParser
################################################################################


################################################################################
## byte generator
################################################################################
def file_byte(fp, chunksize=1024):
  """byte generator"""

  while True:
    chunk = fp.read(chunksize)
    if chunk:
      for byte in chunk : yield byte
    else:
      break
################################################################################


################################################################################
## main
################################################################################
def main:
  """main function"""

  # handle command-line options
  usage = "Usage: %prog [options] in.hex out.v"
  parser = OptionParser(usage=usage)
  parser.add_option("-a", "--address-bits",    dest="aw",     action="store",      default=0,     help="Force use of this many address bits")
  parser.add_option("-s", "--memory-size",     dest="ms",     action="store",      default=0,     help="Force length of memory (number of rows)")
  parser.add_option("-w", "--memory-width",    dest="mw",     action="store",      default=0,     help="Force width of memory (width of a row)")
  parser.add_option("-n", "--no-pad",          dest="nopad",  action="store_true", default=False, help="Do not pad output")
  parser.add_option("-p", "--pad-with-zeroes", dest="padval", action="store_true", default=False, help="Pad with zeroes instead of ones")
  (options, args) = parser.parse_args()

  # parse args
  if (len(args) != 2) : parser.error("Invalid number of arguments.\n")
  fin = args[0]
  fon = args[1]
  modulename = os.path.splitext(os.path.basename(fon))[0]

  # check that files exist
  if (not os.path.isfile(fin)):
    sys.stderr.write("ERROR: could not open source file %s. Cannot continue.\n" % fin)
    sys.exit(-1)

  # get size of file
  fis = os.path.getsize(fin)

  # read to memory
  dat = open(fin, "rb").read()

  # pad to required size
  

  # test if output files are writeable
  if (not os.access(os.path.dirname(fon), os.W_OK | os.X_OK)):
    sys.stderr.write("ERROR: output directory %s is not writeable, or no such path exists.\n" % os.path.dirname(fon))
    sys.exit(-1)

  # 




################################################################################


################################################################################
## entry
################################################################################
if __name__ == "__main__":
  main()
################################################################################

