#!/usr/bin/env python


"""
nc_run.py
Thic script runs cadence tools for compilation, elaboration and simulation of HDL code.
"""


########################################
## imports
########################################

from __future__ import with_statement
import os, sys
from string import split
from optparse import OptionParser, OptionGroup
from subprocess import Popen, PIPE

import logger
import lst_parse

########################################



########################################
## globals
########################################

# debug
DEBUG    = False

# tools
T_VLOG   = "ncvlog"
T_VHDL   = "ncvhdl"
T_ELAB   = "ncelab"
T_SIM    = "ncsim"
T_VIEW   = "simvision"
T_BROW   = "ncbrowse"
T_LINT   = "hal"
T_COV    = "iccr"

# run sequences
RUN_COMP = True
RUN_ELAB = True
RUN_SIM  = True
RUN_LINT = False
RUN_COV  = False

# tools options
WAVES    = False
MEMS     = False
TASKS    = False
FUNCS    = False

# module files & dirs
RTL_TOP  = ""
SIM_TOP  = ""
COV_TOP  = ""

# command files
CDS_LIB  = "cds.lib"
HDL_VAR  = "hdl.var"
CCOV_CF  = "code_coverage.cf"
VLOG_CMD = "ncvlog.args"
VHDL_CMD = "ncvhdl.args"
ELAB_CMD = "ncelab.args"

# log files
VLOG_LOG = "ncvlog.log"
VHDL_LOG = "ncvhdl.log"
ELAB_LOG = "ncelab.log"
SIM_LOG  = "ncsim.log"
RUN_LOG  = "run.log"

# output directories
OUT_DIR  = "../out"
ARG_DIR  = "/arg"
HEX_DIR  = "/hex"
LIB_DIR  = "/lib"
WRK_DIR  = "/lib/work"
LOG_DIR  = "/log"
WAV_DIR  = "/wav"

# list files
RTL_LST  = "rtl.lst"
LIB_LST  = "lib.lst"
SIM_LST  = "sim.lst"
DIR_LST  = "dir.lst"

# vars
debug    = False
out_dir  = OUT_DIR
arg_dir  = OUT_DIR + ARG_DIR
hex_dir  = OUT_DIR + HEX_DIR
lib_dir  = OUT_DIR + LIB_DIR
wrk_dir  = OUT_DIR + WRK_DIR
log_dir  = OUT_DIR + LOG_DIR
wav_dir  = OUT_DIR + WAV_DIR

########################################



########################################
## main
########################################

def main():
  """run_sim main function."""

  global debug, out_dir

  # handle command-line options
  usage = "Usage: %prog [options]"
  parser = OptionParser(usage=usage)
  group = OptionGroup(parser, "Debug Options")
  group.add_option ("-d", "--debug",     dest="debug",        action="store_true", default=DEBUG,    help="turn debug output on")
  parser.add_option_group(group)
  group = OptionGroup(parser, "Flow Options")
  group.add_option ("-c", "--compile",   dest="do_compile",   action="store_true", default=RUN_COMP, help="run compile stage, default: %d" % RUN_COMP)
  group.add_option ("-e", "--elaborate", dest="do_elaborate", action="store_true", default=RUN_ELAB, help="run elaborate stage, default: %d" % RUN_ELAB)
  group.add_option ("-s", "--simulate",  dest="do_simulate",  action="store_true", default=RUN_SIM,  help="run simulate stage, default: %d" % RUN_SIM)
  group.add_option ("-l", "--lint",      dest="do_lint",      action="store_true", default=RUN_LINT, help="run lint stage, default: %d" % RUN_LINT)
  group.add_option ("-v", "--coverage",  dest="do_coverage",  action="store_true", default=RUN_COV,  help="run coverage stage, default: %d" % RUN_COV)
  parser.add_option_group(group)
  group = OptionGroup(parser, "Tools Options")
  group.add_option ("-w", "--waves",     dest="opt_waves",    action="store_true", default=WAVES,    help="turn wave simulation output on, default: %d" % WAVES)
  group.add_option ("-m", "--memories",  dest="opt_mems",     action="store_true", default=MEMS,     help="turn memory simulation on, default: %d" % MEMS)
  group.add_option ("-t", "--tasks",     dest="opt_tasks",    action="store_true", default=TASKS,    help="turn tasks simulation on, default: %d" % TASKS)
  group.add_option ("-f", "--functions", dest="opt_funcs",    action="store_true", default=FUNCS,    help="turn functions simulation on, default: %d" % FUNCS)
  parser.add_option_group(group)
  group = OptionGroup(parser, "Module Options")
  group.add_option (      "--rtl-top",   dest="top_rtl",      action="store_true", default=RTL_TOP,  help="RTL top module, default: %s" % RTL_TOP)
  group.add_option (      "--sim-top",   dest="top_sim",      action="store_true", default=SIM_TOP,  help="SIM top module, default: %s" % SIM_TOP)
  group.add_option (      "--rtl-dir",   dest="top_cov",      action="store_true", default=COV_TOP,  help="COV top module, default: %s" % COV_TOP)
  parser.add_option_group(group)
  group = OptionGroup(parser, "Directory Options")
  group.add_option ("-o", "--out-dir",   dest="out_dir",      action="store",      default=OUT_DIR,  help="output diretctory, default: %s" % OUT_DIR)
  parser.add_option_group(group)
  group = OptionGroup(parser, "Input Files")
  group.add_option (      "--rtl-list",  dest="rtl_list",     action="store",      default=RTL_LST,  help="RTL list file, default: %s" % RTL_LST)
  group.add_option (      "--lib-list",  dest="lib_list",     action="store",      default=LIB_LST,  help="LIB list file, default: %s" % LIB_LST)
  group.add_option (      "--sim-list",  dest="sim_list",     action="store",      default=SIM_LST,  help="SIM list file, default: %s" % SIM_LST)
  group.add_option (      "--dir-list",  dest="dir_list",     action="store",      default=DIR_LST,  help="DIR list file, default: %s" % DIR_LST)
  parser.add_option_group(group)
  (options, args) = parser.parse_args()

  # parse parameters
  if debug : sys.stderr.write("INFO:  Parsing parameters ...\n")
  debug         = options.debug
  do_compile    = options.do_compile
  do_elaborate  = options.do_elaborate
  do_simulate   = options.do_simulate
  do_lint       = options.do_lint
  do_coverage   = options.do_coverage
  opt_waves     = options.opt_waves
  opt_mems      = options.opt_mems
  opt_tasks     = options.opt_tasks
  opt_funcs     = options.opt_funcs
  top_rtl       = options.top_rtl
  top_sim       = options.top_sim
  top_cov       = options.top_cov
  out_dir       = options.out_dir
  rtl_list      = options.rtl_list
  lib_list      = options.lib_list
  sim_list      = options.sim_list
  dir_list      = options.dir_list

  # call nc_run function with parameters from command line (alternatively, call this function when importing this module)
  nc_run( debug=debug,
          do_compile=do_compile, do_elaborate=do_elaborate, do_simulate=do_simulate, do_lint=do_lint, do_coverage=do_coverage,
          opt_waves=opt_waves, opt_mems=opt_mems, opt_tasks=opt_tasks, opt_funcs=opt_funcs,
          top_rtl=top_rtl, top_sim=top_sim, top_cov=top_cov,
          out_dir=out_dir, rtl_list=rtl_list, lib_list=lib_list, sim_list=sim_list, dir_list=dir_list)

########################################



########################################
## nc_run
########################################
def nc_run( debug=DEBUG,
            do_compile=RUN_COMP, do_elaborate=RUN_ELAB, do_simulate=RUN_SIM, do_lint=RUN_LINT, do_coverage=RUN_COV,
            opt_waves=WAVES, opt_mems=MEMS, opt_tasks=TASKS, opt_funcs=FUNCS,
            top_rtl=RTL_TOP, top_sim=SIM_TOP, top_cov=COV_TOP,
            out_dir=OUT_DIR, rtl_list=RTL_LST, lib_list=LIB_LST, sim_list=SIM_LST, dir_list=DIR_LST):
  """nc_run function."""

  global arg_dir, hex_dir, lib_dir, wrk_dir, log_dir, wav_dir

  # setup dir vars
  arg_dir = out_dir + ARG_DIR
  hex_dir = out_dir + HEX_DIR
  lib_dir = out_dir + LIB_DIR
  wrk_dir = out_dir + WRK_DIR
  log_dir = out_dir + LOG_DIR
  wav_dir = out_dir + WAV_DIR


  # create output directories
  for directory in (out_dir, arg_dir, hex_dir, lib_dir, wrk_dir, log_dir, wav_dir):
    if not os.path.exists(directory) : os.makedirs(directory)

  # open & clean logfile
  log = logger.Log(log_filename=log_dir+"/"+RUN_LOG, log_module="NC_RUN", log_to_stderr=debug, log_to_file=True)
  log.clear()
  log.openlog() 

  # parse list files
  log.info("Parsing list files ...")
  (vlog_list, vinc_list, vhdl_list, dir_list) = lst_parse.lst_parse(debug=debug, run_log=None, rtl_list=rtl_list, lib_list=lib_list, sim_list=sim_list, dir_list=dir_list, log=log)

  # prepare for and compile Verilog files
  if do_compile and (len(vlog_list) > 0): 
    log.info("Preparing and compiling Verilog files ...")
    ncvlog(vlog_list, dir_list, log=log)

  # prepare for and compile VHDL files
  if do_compile and (len(vhdl_list) > 0):
    log.info("Preparing and compiling VHDL files ...")
    ncvhdl(vhdl_list, dir_list, log=log)

  # prepare for and run elaboration
  if do_elaborate:
    ncelab(do_coverage=do_coverage, top_rtl=top_rtl, top_sim=top_sim, top_cov=top_cov, sparse=True, timescale=False, args=[], log=log)

  # prepare for and run lint
  if do_lint:
    lint(top_rtl=top_rtl)

  # prepare for and run simulation
  if do_simulate:
    ncsim (top_sim=top_sim, opt_waves=opt_waves, opt_mems=opt_mems, opt_tasks=opt_tasks, do_coverage=do_coverage, licqueue=True, profile=False, args=[], testname="", maxsize="", log=log)

########################################



########################################
## ncvlog
########################################

def ncvlog(verilog_files=[], include_directories=[], args=[], log=None):
  """prepares Verilog compiler command script and runs compile."""

  global out_dir, arg_dir, hex_dir, lib_dir, wrk_dir, log_dir, wav_dir

  log.info("Preparing Verilog compiler command script ...")

  # write cds.lib file
  with open("%s/%s" % (arg_dir, CDS_LIB), "w+") as fo:
    fo.write    ("DEFINE work           ../%s\n" % wrk_dir)

  # write hdl.var file
  with open("%s/%s" % (arg_dir, HDL_VAR), "w+") as fo:
    #fo.write    ("INCLUDE $%s/tools/inca/files/hdl.var\n" % CDS_INST_DIR)
    fo.write    ("DEFINE WORK work\n")

  # write ncvlog arguments file
  with open("%s/%s" % (arg_dir, VLOG_CMD), "w+") as fo:
    fo.write    ("-CDSLIB %s/%s\n" % (arg_dir, CDS_LIB))
    fo.write    ("-HDLVAR %s/%s\n" % (arg_dir, HDL_VAR))
    fo.write    ("-MESSAGES\n")
    fo.write    ("-NOCOPYRIGHT\n")
    fo.write    ("-LOGFILE %s/%s\n" % (log_dir, VLOG_LOG))
    fo.write    ("-define no_macro_msg\n")
    fo.write    ("-DEFINE FAST_FUNC=1\n")
    for arg in args:
      fo.write  ("%s\n" % arg)
    for directory in include_directories:
      fo.write  ("-INCDIR %s\n" % directory)
    for module in verilog_files:
      fo.write  ("%s\n" % module)

  # compile
  log.info("Running Verilog compile ...")  
  try :
    p = Popen(T_VLOG + " -f %s/%s" % (arg_dir, VLOG_CMD), bufsize=-1, shell=True, stdout=PIPE, stderr=PIPE, close_fds=True)
    out = p.stdout.read()
    f_out = open(log_dir+"/ncvlog.out", 'w')
    f_out.write(out)
    f_out.close()
    _module = log.log_module
    log.log_module = "NCVLOG"
    for line in out.splitlines() :
      log.info(line)
      if ((line.find("*E") != -1) or (line.find("*W") != -1)) or (line.find("*F") != -1):
        log.warn(line)
    log.log_module = _module

    if (p.wait()):
      log.err("Error running ncvlog.")
      sys.exit(-1)
    else:
      log.info("Verilog compile OK.")

  except KeyboardInterrupt:
    p.communicate()

########################################



########################################
## ncvhdl
########################################

def ncvhdl(vhdl_files=[], include_directories=[], args=[], log=None):
  """prepares VHDL compiler command script and runs compile."""

  global out_dir, arg_dir, hex_dir, lib_dir, wrk_dir, log_dir, wav_dir

  log.info("Preparing VHDL compiler command script ...")

  # write cds.lib file
  with open("%s/%s" % (arg_dir, CDS_LIB), "w+") as fo:
    fo.write    ("DEFINE work           ../%s\n" % wrk_dir)
    fo.write    ("INCLUDE $CDS_INST_DIR/tools/inca/files/cds.lib")#hdl.var")

  # write hdl.var file
  with open("%s/%s" % (arg_dir, HDL_VAR), "w+") as fo:
    #fo.write    ("INCLUDE $%s/tools/inca/files/hdl.var\n" % CDS_INST_DIR)
    fo.write    ("DEFINE WORK work\n")

  # write ncvhdl arguments file
  with open("%s/%s" % (arg_dir, VHDL_CMD), "w+") as fo:
    fo.write    ("-CDSLIB %s/%s\n" % (arg_dir, CDS_LIB))
    fo.write    ("-HDLVAR %s/%s\n" % (arg_dir, HDL_VAR))
    fo.write    ("-MESSAGES\n")
    fo.write    ("-NOCOPYRIGHT\n")
    fo.write    ("-LOGFILE %s/%s\n" % (log_dir, VLOG_LOG))
    fo.write    ("-V200x\n")
    for arg in args:
      fo.write  ("%s\n" % arg)
    for module in vhdl_files:
      fo.write  ("%s\n" % module)

  # compile
  log.info("Running VHDL compile ...")  
  try :
    p = Popen(T_VHDL + " -f %s/%s" % (arg_dir, VHDL_CMD), bufsize=-1, shell=True, stdout=PIPE, stderr=PIPE, close_fds=True)
    out = p.stdout.read()
    f_out = open(log_dir+"/ncvhdl.out", 'w')
    f_out.write(out)
    f_out.close()
    _module = log.log_module
    log.log_module = "NCVHDL"
    for line in out.splitlines() :
      log.info(line)
      if ((line.find("*E") != -1) or (line.find("*W") != -1)) or (line.find("*F") != -1):
        log.warn(line)
    log.log_module = _module

    if (p.wait()):
      log.err("Error running ncvhdl.")
      sys.exit(-1)
    else:
      log.info("VHDL compile OK.")

  except KeyboardInterrupt:
    p.communicate()

########################################



########################################
## ncelab
########################################

def ncelab (do_coverage=RUN_COV, top_rtl=RTL_TOP, top_sim=SIM_TOP, top_cov=COV_TOP, sparse=True, timescale=False, args=[], log=None):
  """prepares for and launches work library elaboration."""

  global out_dir, arg_dir, hex_dir, lib_dir, wrk_dir, log_dir, wav_dir

  # write coverage file
  if (do_coverage) :
    log.info("Preparing coverage script ...")
    with open("%s/%s" % (arg_dir, CCOV_CF), "w+") as fo:
      fo.write("select_coverage -bet -module %s...\n" % top_cov)
      fo.write("deselect_coverage -bet -module mbist* RAM* v5* ARAMB36_INTERNAL\n")
      ## this would expect redundant default conditions in the code.
      ## f_code_coverage_cf.write("set_implicit_block_scoring -on -if *\n")
      f_code_coverage_cf.write("set_toggle_portsonly\n")
      f_code_coverage_cf.write("set_assign_scoring\n")
      f_code_coverage_cf.write("set_branch_scoring\n")
      f_code_coverage_cf.write("set_glitch_strobe 1 ns\n")
      ## FSM coverage is an involved process, starting with the way RTL is coded.
      ## f_code_coverage_cf.write("select_fsm -module *\n")

  # write ncelab arguments file
  log.info("Preparing elaboration script ...")
  with open("%s/%s" % (arg_dir, ELAB_CMD), "w+") as fo:
    if (do_coverage) :
      fo.write  ("-covfile %s/%s\n" % (arg_dir, CCOV_CF))
    fo.write    ("-MESSAGES\n")
    fo.write    ("-NOCOPYRIGHT\n")
    fo.write    ("-CDSLIB %s/%s\n" % (arg_dir, CDS_LIB))
    fo.write    ("-HDLVAR %s/%s\n" % (arg_dir, HDL_VAR))
    fo.write    ("-LOGFILE %s/%s\n" % (log_dir, ELAB_LOG))
    fo.write    ("-SNAPSHOT work.bench:rtl\n")
    fo.write    ("-ACCESS +RWC\n")
    if (timescale) :
      fo.write  ("-TIMESCALE %s\n" % timescale)
    fo.write    ("-NOTIMINGCHECKS\n")
    fo.write    ("-NO_TCHK_MSG\n")
    fo.write    ("-NOWARN BNDMEM\n")                   # Option added to avoid warnings from FPGA memory model.
    fo.write    ("-NOWARN MEMODR\n")                   # Option added to avoid warnings for readmem order.
    fo.write    ("-NOWARN WARIPR\n")                   # Option added to avoid warnings from encripted modules.
    if (sparse) :
      fo.write  ("-sparsearray 100\n")                 # Option added to improve simulation speed.
    fo.write    ("work.%s\n" % top_sim)

  # compile
  log.info("Running elaboration ...")  
  try :
    p = Popen(T_ELAB + " -f %s/%s" % (arg_dir, ELAB_CMD), bufsize=-1, shell=True, stdout=PIPE, stderr=PIPE, close_fds=True)
    out = p.stdout.read()
    f_out = open(log_dir+"/ncelab.out", 'w')
    f_out.write(out)
    f_out.close()
    _module = log.log_module
    log.log_module = "NCELAB"
    for line in out.splitlines() :
      log.info(line)
      if ((line.find("*E") != -1) or (line.find("*W") != -1)) or (line.find("*F") != -1):
        log.warn(line)
    log.log_module = _module

    if (p.wait()):
      log.err("Error running ncelab.")
      sys.exit(-1)
    else:
      log.info("Elaboration OK.")

  except KeyboardInterrupt:
    p.communicate()

########################################



########################################
## nclint
########################################

def nclint (top_rtl=RTL_TOP):
  """prepares for and runs lint."""

  global out_dir, arg_dir, hex_dir, lib_dir, wrk_dir, log_dir, wav_dir

  log.info("Preparing lint script ...")

  arg  = ""
  arg += " -BB_CELLDEFINE"
  arg += " -nocheck ALL"
  arg += " -check ALL_RTL"
  arg += " -nocheck RTL_NAMING"
  arg += " -nocheck RTL_FILEFORMAT"
  arg += " -check ALL_NETLIST"
  arg += " -CDSLIB %s/%s" % (arg_dir, CDS_LIB)
  arg += " -HDLVAR %s/%s" % (arg_dir, HDL_VAR)
  arg += " -halsynth_detailcheck"
  arg += " -design_facts %s/%s" % (log_dir, "hal.design_facts")
  arg += " -stats"
  arg += " -top %s" % top_rtl
  arg += " -log "+dir_log+"hal.log"
  arg += " work.bench:rtl"

  # TODO to be fixed
  pass
 
  try:
    p = Popen ("hal "+arg, shell=True, close_fds=True)
 
    arg  = ""
    arg += " -cdslib "+arg_dir+"cds.lib"
    arg += " -hdlvar "+arg_dir+"hdl.var"
    arg += " -sortby severity"
    arg += " -report "+dir_log+"hal_filtered.log"
    arg += " "+dir_log+"hal.log"
    #foreach tag (`cat hal_filter_tags.lst`)
    #  echo "-filter tag=$tag"                                              >> ../out/arg/ncbrowse.args
    #end
  
    p = Popen ("ncbrowse "+arg, shell=True, close_fds=True)
  except KeyboardInterrupt:
    p.communicate()

########################################



########################################
## ncsim
########################################

def ncsim (top_sim=SIM_TOP, opt_waves=WAVES, opt_mems=MEMS, opt_tasks=TASKS, do_coverage=RUN_COV, licqueue=True, profile=False, args=[], testname="", maxsize="", log=None):
  """prepares and runs simulation."""

  global out_dir, arg_dir, hex_dir, lib_dir, wrk_dir, log_dir, wav_dir

  # prepare simulation script
  log.info("Preparing simulation script ...")
  arg  = "" 
  if (licqueue) :
    arg +=  " -LICQUEUE"
  arg +=    " -MESSAGES"
  arg +=    " -NOCOPYRIGHT"
  arg +=    " -CDSLIB %s/%s" % (arg_dir, CDS_LIB)
  arg +=    " -HDLVAR %s/%s" % (arg_dir, HDL_VAR)
  arg +=    " -INPUT %s/%s" % (arg_dir, "ncsim.tcl")
#  arg +=    " -LOGFILE %s/%s" % (log_dir, SIM_LOG) # TODO add testname
  arg +=    " -LOGFILE /dev/null"
  if (profile) :
    arg +=  " -profile -profoutput %s/%s" % (log_dir, "ncprof.out") ## Option added to debug performance issue
  arg +=    " work.bench:rtl"
  for item in args:
    arg +=  " %s" % item
  if (do_coverage) :
    arg +=  " -COVOVERWRITE"

  # prepare simulator command script
  log.info("Preparing simulation command script ...")
  with open("%s/%s" % (arg_dir, "ncsim.tcl"), "w+") as fo:
    if (opt_waves) :
      if (maxsize != "") :
        fo.write  ("database -open waves -shm -maxsize "+maxsize+" -into "+wav_dir+"\n")
      else :
        fo.write  ("database -open waves -shm -into "+wav_dir+"\n")
      fo.write    ("probe -create -database waves "+top_sim+" -shm -all -depth all")
      if (opt_mems):
        fo.write  (" -memories")
      if (opt_tasks):
        fo.write  (" -tasks")
      fo.write    ("\n")
    if (do_coverage) :
      fo.write("coverage -setup -design "+top_sim+"\n")
      fo.write("coverage -setup -dut "+top_sim+"\n")
      fo.write("coverage -setup -testname "+testname+"\n")
      fo.write("coverage -setup -workdir "+log_dir+"/work\n")
      ##fo.write("coverage -code -score ALL\n")
      ##fo.write("coverage -fsm -database -local_db ${"+top_sim+"}_${i}.fsm\n")
      ##fo.write("coverage -toggle -database -aggregate_db $CODE_COV_TOP.mst\n")
    fo.write("run\n")
    fo.write("exit\n")
    fo.close()

  # run simulation
  log.info("Running test %s ..." % testname)

  log.info("ncsim " + arg)

  try:
    p = Popen ("ncsim "+arg, shell=True, stdout=PIPE)
    ret = p.communicate()
    _module = log.log_module
    log.log_module = "NCSIM"

    log.log_module = _module

    if (p.returncode) : 
      log.err("Error while running ncsim")
      sys.exit(-1)
    else :
      log.info(ret[0])
      log.info(ret[1])
      log.info("Simulation OK.")
  except KeyboardInterrupt:
    p.terminate()
    
########################################



########################################
## start
########################################

if __name__ == "__main__":
  main()

########################################

