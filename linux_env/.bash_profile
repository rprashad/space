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

function setps1() {
  case "$TERM" in
  linux|screen|xterm*|rxvt*)
      PS1="\[\033[34m\][\$(date +%H%M)][\u@\h:\w]$ "
      ;;
  *)
      ;;
  esac
} # setps1

function screen_sessions() {
  screens=`which screen | grep -iv No`
  if [[ ! -z "$screens" ]]; then
    goscreen.pl
  fi
} # screen_sessions

function altprofiles() {
# make custom profile.d directory
  if [[ ! -d $HOME/.profile.d ]]; then
    mkdir $HOME/.profile.d;
  else
    for i in `ls $HOME/.profile.d/`; do
      source $HOME/.profile.d/$i
    done
  fi
} # altprofiles

function mkdestdir() {
  DEST=$1
  if [[ ! -d "$DEST" ]]; then
    echo "Creating destination directory: $DEST"
    mkdir -p $DEST
  fi

} # makedestdir

function syncfile() {
  SYNC_SOURCE=$1
  SYNC_DEST=$2
  BAK="$SYNC_DEST.bak"

  # echo "SRC: $SYNC_SOURCE DST: $SYNC_DEST BAK: $BAK"
  
  md5_src=`md5sum $SYNC_SOURCE | awk '{print \$1}'`;
  md5_dst=`md5sum $SYNC_DEST 2> /dev/null | awk '{print \$1}'`;
  if [[ "$md5_src" != "$md5_dst" ]]; then
    mv $SYNC_DEST $BAK 2> /dev/null
    echo "Syncing $SYNC_SOURCE -> $SYNC_DEST"
    ln $SYNC_SOURCE $SYNC_DEST
  fi
} # syncfile

function synctools() {
  SOURCE=$1
  DEST=$2
  cd $SOURCE
  # may/may not be a git repo
  git pull 2> /dev/null
   for i in `ls $SOURCE`; do
     if [[ ! -e "/$DEST/$i" ]]; then
       S="$SOURCE/$i"
       D="$DEST/$i"
       syncfile $S $D
     fi
  done
} # synctools

function syncall() {
# sync tools dir
  linux_tools_src="$HOME/git/space/linux_env/tools"
  linux_tools_dst="$HOME/bin/tools"
  mkdestdir $linux_tools_dst
  synctools $linux_tools_src $linux_tools_dst

# sync .bash_profile
  bash_src="$HOME/git/space/linux_env/.bash_profile"
  bash_dst="$HOME/.bash_profile"
  syncfile $bash_src $bash_dst

# sync .screenrc
  screen_src="$HOME/git/space/linux_env/.screenrc"
  screen_dst="$HOME/.screenrc"
  syncfile $screen_src $screen_dst

# sync .vimrc
  vim_src="$HOME/git/space/linux_env/.vimrc"
  vim_dst="$HOME/.vimrc"
  syncfile $screen_src $screen_dst

}

function timesync() {
  LEN=3600
  CDATE=`date +%s`
  DEBUG=0

  if [[ -e "$HOME/.lastenvsync" ]]
  then
    ODATE=`cat $HOME/.lastenvsync`
    DIFF=$(( $CDATE - $ODATE ))
    if [[ $DIFF > $LEN ]]
      then
        syncall
        echo $CDATE > $HOME/.lastenvsync
    fi
  else
    DIFF=0
    echo $CDATE > $HOME/.lastenvsync
    syncall
  fi
}

################################ END FUNCTIONS
# setps1
setps1
# grab github tools
bootstrap
# sync only by time
timesync
# check for existing screen sessions
screen_sessions
# check for local/alt profiles
altprofiles

