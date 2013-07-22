#!/bin/bash

# symlink bin from github space repo "linux_env"
# rajendra.prashad <nprashad@gmail.com>

SOURCE="$HOME/git/space/linux_env/tools/"
DEST="$HOME/bin/tools"
LEN=86400
#LEN=10
CDATE=`date +%s`

if [ ! -d "$DEST" ]
then
  echo "Creating destination directory: $DEST"
  mkdir -p $DEST
fi

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

if [[ $DIFF > $LEN ]]
  then
    cd $SOURCE
    echo "Git PULL"
    git pull
    syncit $SOURCE $DEST
    ln -sf "$HOME/git/space/linux_env/.bash_profile" "$HOME/.bash_profile"
    echo $CDATE > $HOME/.lastenvsync
else
  # echo "no changes yet $CDATE $DIFF"
fi

