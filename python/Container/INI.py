#!/usr/bin/env python

import sys, re
from pprint import pprint

class INI():
 """The Perl equivalent to Container::INI"""
 def __init__(self,cfg):
   self.config = self.source_config(cfg)
   

 def source_config(self,cfg):
  """General workhorse of Container.INI"""
  config = []
  try:
    CONFIG = file(cfg, 'r')
    for line in CONFIG:
      # config.append(line)
      if (line 
  
  except IOError as e:
    sys.stderr.write("I/O Error {0} - {1}".format(e.errno, e.strerror))

  return config
  
 
 def dump(self):
  """Atempt to dump"""
  pprint(self.config)

c = INI("example1.ini")

c.dump()
