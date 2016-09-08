DICTIONARY="/usr/local/share/stardict"

if [[ ! -d "$DICTIONARY" ]]; then
  echo "Making directory: $DICTIONARY"
  sudo mkdir -p $DICTIONARY
  sudo rsync -av $HOME/git/space/linux_env/dictionary/ $DICTIONARY
  echo "Dictionary Added, please install sdcv"
fi

alias sdcv="sdcv -2 ${DICTIONARY}"
