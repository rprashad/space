#!/usr/bin/env python

import PyFork
import sys, time, subprocess, os

# PyFork.atomic.debug = True

counter = 0
def myfunc(name):
  print str(os.getpid()) + " is sleeping"
  return

def myblah(me): 
  print str(os.getpid()) + " is running under child!"
  time.sleep(15)
  return

f = PyFork.atomic(detach=True)
print f.spawn(3,myfunc,str(os.getpid()))

print "Hello World"

g = PyFork.atomic()
g.spawn(10, myblah, "raj")
