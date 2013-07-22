#!/bin/bash

# symlink bin from github space repo "linux_env"
# rajendra.prashad <nprashad@gmail.com>

SOURCE="$HOME/git/space/linux_env/tools/"
DEST="$HOME/bin/tools"
LEN=3600
CDATE=`date +%s`
DEBUG=0

if [[ ! -d "$DEST" ]]; then
  echo "Creating destination directory: $DEST"
  mkdir -p $DEST
fi

function syncit() {
  SOURCE=$1
  DEST=$2
  echo "Syncing Tools"
  cd $SOURCE
  git pull
  for i in `ls $SOURCE`; do
     if [[ ! -e "/$DEST/$i" ]]; then
       echo "Syncing: $i"
       ln -sf $SOURCE/$i $DEST/$i
     fi
  done
  ln -sf "$HOME/git/space/linux_env/.bash_profile" "$HOME/.bash_profile"
} # syncit


if [[ -e "$HOME/.lastenvsync" ]]
then
  ODATE=`cat $HOME/.lastenvsync`
  DIFF=$(( $CDATE - $ODATE ))
  if [[ $DIFF > $LEN ]]
    then 
      syncit $SOURCE $DEST
      echo $CDATE > $HOME/.lastenvsync
  fi
else
  DIFF=0
  echo $CDATE > $HOME/.lastenvsync
  syncit $SOURCE $DEST
fi

