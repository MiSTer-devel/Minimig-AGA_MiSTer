#!/usr/bin/env python

"""
logger.py
This class takes care of logging & displaying.
"""

########################################
## imports
########################################

import os, sys, datetime

########################################



########################################
## global constants
########################################

# file & module name
LOG_FILENAME  = "run.log"
LOG_MODULE    = "LOG"

# levels
LOG_ERR       = 0
LOG_WARN      = 1
LOG_INFO      = 2
LOG_LEVEL     = ["ERR ", "WARN", "INFO"]

# time format
T_FMT         = "%Y-%m-%d %H:%M:%S"
T_FUNC        = datetime.datetime.today().strftime(T_FMT)

########################################



########################################
## Log class
########################################

class Log:
  """Logging and diplaying of notices, warnings and errors."""

  # class variables
  log_filename  = LOG_FILENAME
  log_module    = LOG_MODULE
  log_to_stderr = False
  log_to_file   = True
  log_file      = None
  opened        = False

  # init
  def __init__(self, log_filename=LOG_FILENAME, log_module=LOG_MODULE, log_to_stderr=False, log_to_file=True):
    self.log_filename   = log_filename
    self.log_module     = log_module
    self.log_to_stderr  = log_to_stderr
    self.log_to_file    = log_to_file
    if not self.opened : self.openlog()

  # del
  def __del__(self):
    if self.opened : self.closelog()

  # clear
  def clear(self):
    if self.opened : self.closelog()
    if self.log_to_file : os.remove(self.log_filename)

  # log
  def log(self, text="", level=LOG_INFO):
    if self.log_to_stderr : sys.stderr.write("%s : %s : %s : %s\n" % (self.log_module, datetime.datetime.today().strftime(T_FMT), LOG_LEVEL[level], text))
    elif level == LOG_ERR : sys.stderr.write("%s\n" % text)
    if self.log_to_file:
      if not self.opened : self.openlog()
      self.log_file.write("%s : %s : %s : %s\n" % (self.log_module, datetime.datetime.today().strftime(T_FMT), LOG_LEVEL[level], text))
    if level == LOG_ERR : sys.exit(-1)

  # info
  def info(self, text=""):
    self.log(text, level=LOG_INFO)

  # warn
  def warn(self, text=""):
    self.log(text, level=LOG_WARN)

  # err
  def err(self, text=""):
    self.log(text, level=LOG_ERR)

  # openlog
  def openlog(self):
    self.log_file = open(self.log_filename, "ab+")
    opened = True

  # closelog
  def closelog(self):
    self.log_file.close()
    self.log_file = None
    opened = False

########################################

