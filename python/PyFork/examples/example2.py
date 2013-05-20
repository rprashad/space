#!/usr/bin/env python

import PyFork
import sys, time, subprocess, os

PyFork.atomic.debug = True

counter = 0
def myfunc(name):
  time.sleep(10)
  print str(os.getpid()) + " is sleeping"

f = PyFork.atomic(detach=False)

if (f.isalaive() != True):
  f.spawn(5,myfunc,str(os.getpid()))
else:
  while(f.isalive()):
    print "waiting for child - 
