dic="/usr/share/stardict/dic/"

if [[ ! -d "$dic" ]]; then
  echo "Making dictionary directory: $dic"
  sudo mkdir -p /usr/local/share/stardict/dic/
  sudo rsync -av $HOME/git/space/linux_env/dictionary/ /usr/local/share/stardict/dic/
  echo "Dictionary Added, please install sdcv"
fi

