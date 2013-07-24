### Rajendra Prashad 

PATH=$PATH:$HOME/bin:$HOME/bin/tools:/usr/bin:/usr/sbin:/usr/local/bin:/bin:/sbin
export PERL5LIB=/data/ops/lib/:$HOME/space/perl
export PYTHONPATH=$HOME/space/python

function bootstrap() {
  if [[ ! -d "$HOME/git/space" ]]; then
    mkdir -p "$HOME/git/space"
    cd $HOME/git
    git clone http://github.com/rprashad/space space
  fi
}

bootstrap
# sync tools
$HOME/git/space/linux_env/tools/linuxenv_sync.sh

case "$TERM" in
linux|screen|xterm*|rxvt*)
    PS1="\[\033[34m\][\$(date +%H%M)][\u@\h:\w]$ "
    ;;
*)
    ;;
esac

screens=`which screen`
if [[ ! -z "$screens" ]]; then
  goscreen.pl
fi

# make custom profile.d directory
if [[ ! -d $HOME/.profile.d ]]; then
  mkdir $HOME/.profile.d;
else
  for i in `ls $HOME/.profile.d/`; do
    source $HOME/.profile.d/$i
  done
fi

