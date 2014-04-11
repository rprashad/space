#!/usr/bin/env python

import yaml, sys, os.path

arglen = len(sys.argv)
if arglen == 2 and os.path.isfile(sys.argv[1]):
  try:
    print yaml.load(open(sys.argv[1], 'r')) 
  except Exception as e:
    print "Error %s" % e

