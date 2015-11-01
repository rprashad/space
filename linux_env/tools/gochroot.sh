#!/bin/bash

env = $1

if [[ -z "$env" ]]; then
  echo "Need to specify chroot directory!"
  exit 2
elif [[ ! -e "$env/bin/bash" ]]; then
  echo "This doesn't look like a chroot environment, aborting"
  exit 2
fi


echo "Setting Up Env"
mount -t proc /proc $env/proc
mount -t sysfs /sys $env/sys
mount -o bind /dev $env/dev
echo "Chroot'ing to $env"
chroot $env /bin/bash
echo "Cleaning Up"
umount $env/proc
umount $env/sys
umount $env/dev
echo "Finished"
