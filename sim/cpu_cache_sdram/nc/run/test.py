#!/usr/bin/python

import sys, os, copy

sys.path.append("../../../common/")
import nc_run
import lst_parse
import logger


# defines
debug         = True
do_compile    = True
do_elaborate  = True
do_simulate   = True
do_lint       = False
do_coverage   = False
opt_waves     = True
opt_mems      = True
opt_tasks     = True
opt_funcs     = True
top_rtl       = "cpu_cache_sdram_tb"
top_sim       = "cpu_cache_sdram_tb"
top_cov       = "cpu_cache_sdram_tb"
out_dir       = "../out"
rtl_list      = "rtl.lst"
lib_list      = "lib.lst"
sim_list      = "sim.lst"
dir_list      = "dir.lst"

# run test
nc_run.nc_run(debug=debug,
              do_compile=do_compile, do_elaborate=do_elaborate, do_simulate=do_simulate, do_lint=do_lint, do_coverage=do_coverage,
              opt_waves=opt_waves, opt_mems=opt_mems, opt_tasks=opt_tasks, opt_funcs=opt_funcs,
              top_rtl=top_rtl, top_sim=top_sim, top_cov=top_cov,
              out_dir=out_dir, rtl_list=rtl_list, lib_list=lib_list, sim_list=sim_list, dir_list=dir_list)


