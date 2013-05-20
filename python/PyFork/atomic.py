#!/usr/bin/env python
#    copyright 2013 - Rajendra Prashad (nprashad@gmail.com)
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

import os,sys

class atomic(object):
 pids = []
 debug = False
 detach = False
 maxchild = 10

 def debugit(self, msg):
   """general debugger method"""
   if (self.debug == True):
     print(msg)

 def isparent(self):
  """public method to check if we're the parent"""
  try:
   if (os.getpid() == self.parent):
    return True
  except NameError:
    return False
  return False

 def spawn(self, num=1, func=None, args=123):
  """Fork a new child from parent for mainly safety concerns
     if you need for fork from a child, then instantiate a new PyFork object
     simply instantiate a new PyFork object

     Optionally - pass in a function and arguments for handling and return
  """
  if (self.isparent() == True):
    if (num > self.maxchild):
      raise AttributeError(" PyFork.atomic.maxchild=" + str(self.maxchild) + ", but number spawned is: " + str(num))
        
    for kids in range(num):
     pid = os.fork()
     if (self.isparent() == True):
       self.debugit(str(pid) + " added to pidlist")
       self.pids.append(pid)
     else:
       if (hasattr(func, '__call__') == True):
         return func(args)
       return 
  # return the list of kids spawned
  return self.pids

 def __init__(self,maxchild=10,detach=True):
  """PyFork constructor
      atomic() may spawn children on instantiation or by using the spawn() method
      you may detach your parent process (default) or forcefully terminate child processes
      when the parent has exited.
  """

  self.detach = detach
  self.parent = os.getpid()
  self.debugit("parent: " + str(self.parent))

 def clearpids(self, pids):
  """ Remove a list of pids from process list """
  for i in pids:
    self.debugit("removing pid: " + str(i))
    try: 
      pids.remove(i)
    except:
     # try to continue
     self.debugit(str(i) + " does not exist in process list")
     pass 

 def managepids(self, pids=None, signal=False, dsig=1): 
  """ general pid manager - to be called in main event loop
      1) loop through process list
      2) remove child from list if finished
      3) append completed pid and status code to a return list
      4) once all pids have been removed from the process list - signal status of 0
  """
  retval = { 'status' : 0 , 'pids': [] }
  if (self.isparent() == True):
    # check if specific pids are passed in - otherwise assume what's in process list
    pids = pids if (type(pids) == 'list') else self.pids
    try:
     for p in pids:
      if (signal == True):
        self.debugit("signaling child [" + str(p) + "] with " + str(dsig))
        os.kill(p, dsig)
      pstatus = os.waitpid(p, 1)
      # self.debugit("pid: " + str(p) + " returned with " + str(pstatus))
      retval['status'] = retval['status'] + 1
      retval['pids'].append(p)
    except IndexError:
      self.clearpids(retpids)
  return retval

 def alive(self):
  """ an easy interface for detecting if all threads have finished
      this is a basic wrapper for managepids
  
      return True if we're still waiting for children
  """

  if (self.managepids()['status'] > 0):
    return True
  else:
    return False

 def __del__(self):
  """ before the parent exits - clean up """
  if (self.isparent() == True):
    if (self.detach == False):
      cleaned = self.managepids(signal=True)
      self.debugit("pids cleaned: ")
      self.debugit(cleaned)

