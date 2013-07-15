#!/bin/bash

# symlink bin from github space repo "linux_env"
# rajendra.prashad <nprashad@gmail.com>

SOURCE="$HOME/git/space/linux_env/bin/"
DEST="$HOME/bin"
LEN=86400
#LEN=10
CDATE=`date +%s`

function syncit() {
SOURCE=$1
DEST=$2
  for i in `ls $SOURCE`
    do
     echo "Syncing: $i"
     ln -sf $SOURCE/$i $DEST/$i
  done
}

if [ -e "$HOME/.lastenvsync" ]
then
  ODATE=`cat $HOME/.lastenvsync`
  DIFF=$(( $CDATE - $ODATE ))
else
  DIFF=0
  echo $CDATE > $HOME/.lastenvsync
fi

if [ $DIFF -gt $LEN ]
  then
    cd $SOURCE
    git pull
    syncit $SOURCE $DEST
    ln -sf "$HOME/git/space/linux_env/.bash_profile" "$HOME/.bash_profile"
    echo $CDATE > $HOME/.lastenvsync
else
  echo "no changes yet $CDATE $DIFF"
fi

