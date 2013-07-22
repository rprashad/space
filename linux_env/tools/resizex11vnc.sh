#!/bin/bash

# rajendra prashad nprashad@gmail.com

CVT=`cvt 1600 1200 | grep Mode | cut -c10-`
RES=`echo $CVT | awk '{print $1}'`
xrandr --newmode $CVT
xrandr --addmode VGA-1 $RES
xrandr --output VGA-1 --mode $RES
