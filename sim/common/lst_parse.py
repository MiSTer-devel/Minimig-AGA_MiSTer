#!/usr/bin/env python


"""
lst_parse.py
Thic script parses file lists (rtl, sim, lib, dir).
"""


########################################
## imports
########################################

from __future__ import with_statement
import os, sys, datetime
from string import split
from optparse import OptionParser, OptionGroup

import logger

########################################



########################################
## globals
########################################

# debug
DEBUG    = False
RUN_LOG  = "run.log"

# list files
RTL_LST  = "rtl.lst"
LIB_LST  = "lib.lst"
SIM_LST  = "sim.lst"
DIR_LST  = "dir.lst"

# variables
glog     = None

########################################



########################################
## main
########################################

def main():
  """lst_parse main function."""

  global glog

  # handle command-line options
  usage = "Usage: %prog [options]"
  parser = OptionParser(usage=usage)
  parser.add_option ("-d", "--debug",     dest="debug",        action="store_true", default=DEBUG,    help="turn debug output on")
  parser.add_option (      "--log",       dest="logfile",      action="store",      default=RUN_LOG,  help="run log file,  default: %s" % RUN_LOG)
  parser.add_option ("-r", "--rtl-list",  dest="rtl_list",     action="store",      default=RTL_LST,  help="RTL list file, default: %s" % RTL_LST)
  parser.add_option ("-l", "--lib-list",  dest="lib_list",     action="store",      default=LIB_LST,  help="LIB list file, default: %s" % LIB_LST)
  parser.add_option ("-s", "--sim-list",  dest="sim_list",     action="store",      default=SIM_LST,  help="SIM list file, default: %s" % SIM_LST)
  parser.add_option ("-i", "--dir-list",  dest="dir_list",     action="store",      default=DIR_LST,  help="DIR list file, default: %s" % DIR_LST)
  (options, args) = parser.parse_args()

  # parse parameters
  debug         = options.debug
  run_log       = options.logfile
  rtl_list      = options.rtl_list
  lib_list      = options.lib_list
  sim_list      = options.sim_list
  dir_list      = options.dir_list

  # call lst_parse function with parameters from command line (alternatively, call this function when importing this module)
  lst_parse(debug=debug, run_log=run_log, rtl_list=rtl_list, lib_list=lib_list, sim_list=sim_list, dir_list=dir_list)

########################################



########################################
## lst_parse
########################################

def lst_parse(debug=DEBUG, run_log=RUN_LOG, rtl_list=RTL_LST, lib_list=LIB_LST, sim_list=SIM_LST, dir_list=DIR_LST, log=None):
  """lst_parse function."""

  global glog

  # create log
  if log is None : log = logger.Log(log_filename=run_log, log_module="LST_PARSE", log_to_stderr=debug, log_to_file=True)
  glog = log

  # remember log module and set it to "LST_PARSE"
  log_module = log.log_module
  log.log_module = "LST_PARSE"

  # create file arrays
  log.info("Creating file arrays ...")
  rtl_vlog = []
  rtl_vinc = []
  rtl_vhdl = []
  lib_vlog = []
  lib_vinc = []
  lib_vhdl = []
  sim_vlog = []
  sim_vinc = []
  sim_vhdl = []
  inc_dirs = []

  # parse file lists
  log.info("Parsing file lists ...")

  if os.path.exists(rtl_list):
    (rtl_vlog, rtl_vinc, rtl_vhdl) = parse_list_file(rtl_list, log=log)
  else:
    log.warn("Input file missing: %s" % rtl_list)

  if os.path.exists(lib_list):
    (lib_vlog, lib_vinc, lib_vhdl) = parse_list_file(lib_list, log=log)
  else:
    log.warn("Input file missing: %s" % lib_list)

  if os.path.exists(sim_list):
    (sim_vlog, sim_vinc, sim_vhdl) = parse_list_file(sim_list, log=log)
  else:
    log.warn("Input file missing: %s" % sim_list)

  if os.path.exists(dir_list):
    inc_dirs = parse_list_file(dir_list, log=log, type=1)
  else:
    log.warn("Input file missing: %s" % dir_list)

  # check files
  log.info("Checking files ...")
  if len(rtl_vlog) == 0 and len(rtl_vhdl) == 0:
    log.warn("No files in RTL list.")
  if len(lib_vlog) == 0 and len(lib_vhdl) == 0:
    log.warn("No files in LIB list.")
  if len(sim_vlog) == 0 and len(sim_vhdl) == 0:
    log.warn("No files in SIM list.")
  if len(rtl_vlog) == 0 and len(rtl_vhdl) == 0 and len(lib_vlog) == 0 and len(lib_vhdl) == 0 and len(sim_vlog) == 0 and len(sim_vhdl) == 0:
    log.err("No source file(s).")
  if len(inc_dirs) == 0:
    log.warn("No include directories.")

  # join lists
  log.info("Joining lists ...")
  vlog_list = []
  vinc_list = []
  vhdl_list = []
  vlog_list = sim_vlog + lib_vlog + rtl_vlog
  vinc_list = sim_vinc + lib_vinc + rtl_vinc
  vhdl_list = sim_vhdl + lib_vhdl + rtl_vhdl

  # check that files exist
  log.info("Checking that files exist ...")
  temp_list = vlog_list + vinc_list + vhdl_list + inc_dirs
  for fil in temp_list:
    if not os.path.exists(fil):
      log.err("Missing file/dir %s." % fil)

  # reset log module
  log.log_module = log_module


  # return parsed lists
  # TODO maybe should return separate lists (lib_vlog, sim_vlog, ...)
  return (vlog_list, vinc_list, vhdl_list, inc_dirs)

########################################



########################################
## parse_list_file
########################################

def parse_list_file(listfile, log, type=0):
  """parse_list_file function."""

  log.info("Parsing file %s ..." % listfile)

  if type == 0: # files
    verilog_files = []
    verilog_includes = []
    vhdl_files = []
    with open(listfile, "r") as fin:
      for line in fin:
        f = line.strip()
        if   f[-2:] == ".v"   :
          log.info("Verilog file found: %s" % f)
          verilog_files.append(f)
        elif f[-3:] == ".vh"  :
          log.info("Verilog include file found: %s" % f)
          verilog_includes.append(f)
        elif f[-4:] == ".vhd" :
          log.info("VHDL file found: %s" % f)
          vhdl_files.append(f)
        elif f != ""          :
          log.info("Ignoring file %s" % f)
    return (verilog_files, verilog_includes, vhdl_files)
  else: # dirs
    dirs = []
    with open(listfile, "r") as fin:
      for line in fin:
        f = line.strip()
        if f != "":
          dirs.append(f)
          log.info("Adding directory %s" % f)
    return dirs

########################################



########################################
## start
########################################

if __name__ == "__main__":
  main()

########################################

