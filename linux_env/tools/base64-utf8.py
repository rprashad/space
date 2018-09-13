#!/usr/bin/env python3

import base64
from pprint import pprint
from sys import argv

def base64_decode(data):
    return base64.b64decode(data.encode('utf8')).decode('utf8')

def base64_encode(data):
    return base64.b64encode(data.encode('utf8')).decode('utf8')


if __name__ == '__main__':

  if 'decode' in argv:
      print(base64_decode("".join(argv[2:])))
  elif 'encode' in argv:
      print(base64_encode("".join(argv[2:])))
  else:
      print("base64-utf8.py encode|decode [DATA]\n")
