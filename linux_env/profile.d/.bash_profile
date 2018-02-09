#!/usr/bin/env bash
### Rajendra Prashad 

PATH=$PATH:$HOME/bin:$HOME/bin/tools:/usr/bin:/usr/sbin:/usr/local/bin:/bin:/sbin
alias jsoncheck='python -mjson.tool'

# fix window sizes
shopt -s checkwinsize

# hide a file
function dot() {
  file=$1

  if [[ $file =~ ^[.] ]]; then
    echo "file $file already dotted"
  else
    dfile=".$file"
    mv $file $dfile 2> /dev/null
    if [[ -e $dfile ]]; then
      echo "$dfile dotted"
    else 
      echo "cannot find dotfile ('.$dfile')"
    fi
  fi
}

# unhide
function undot() {
  file=$1

  if [[ $file =~ ^[.] ]]; then
    udfile=`echo $file | sed 's/^\.//'`
    mv $file $udfile 2> /dev/null
    if [[ -e $udfile ]]; then
      echo ".$udfile undotted"
    else 
      echo "cannot find undotfile ('$udfile')"
    fi
  else
    echo "$file not matched!"
  fi
}

function bootstrap() {
  if [[ ! -d "$HOME/git/space" ]]; then
    mkdir -p "$HOME/git/space" 2> /dev/null
    if [[ $? == 0 ]] ; then
      cd $HOME/git
      git clone http://github.com/rprashad/space space
  else
    echo "bootstrap error ocurred"
  fi
  fi
}

function setps1() {
  fgchoice=$1
  bgchoice=$2
  prompt='[\u@\h \W$(__git_ps1 " (%s)")]\$ '

  if [[ $fgchoice == "default" ]]; then
      export PS1=$prompt
      reset
      echo "default set"
      return
  elif [[ $fgchoice == "white" ]]; then
    fg=37
  elif [[ $fgchoice == "red" ]]; then
    fg=31
  elif [[ $fgchoice == "green" ]]; then
    fg=32
  elif [[ $fgchoice == "yellow" ]]; then
    fg=33
  elif [[ $fgchoice == "blue" ]]; then
    fg=34
  elif [[ $fgchoice == "magenta" ]]; then
    fg=35
  elif [[ $fgchoice == "cyan" ]]; then
    fg=36
  fi

  if [[ $bgchoice == "black" ]]; then
    bg=40
  elif [[ $bgchoice == "red" ]]; then
    bg=41
  elif [[ $bgchoice == "green" ]]; then
    bg=42
  elif [[ $bgchoice == "yellow" ]]; then
    bg=43
  elif [[ $bgchoice == "blue" ]]; then
    bg=44
  elif [[ $bgchoice == "magenta" ]]; then
    bg=45
  elif [[ $bgchoice == "cyan" ]]; then
    bg=46
  fi

  if [[ "$fgchoice" ]] && [[ "$bgchoice" ]]; then
    echo "FG $fgchoice ($fg) BG $bgchoice ($bg)"
    case "$TERM" in
    linux|screen|xterm*|rxvt*)
         color="\[\033[${bg}m\]\[\e[1;${fg}m\]"
         PS1="${color}${prompt}"
        ;;
    *)
        PS1=$prompt
        ;;
    esac
    # setps1
fi
}

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

function syncfile() {
  SYNC_SOURCE=$1
  SYNC_DEST=$2

  echo "Syncing File $SYNC_SOURCE -> $SYNC_DEST"
  rsync --suffix=.bak $SYNC_SOURCE $SYNC_DEST
} # syncfile

function syncdir () {
  SYNC_SOURCE=$1
  SYNC_DEST=$2

  echo "Syncing Directory $SYNC_SOURCE -> $SYNC_DEST"
  rsync -ap $SYNC_SOURCE $SYNC_DEST
} # syncdir

function syncall() {

# sync .profile.d files
  profiled_src="$HOME/git/space/linux_env/profile.d/"
  profiled_dst="$HOME/.profile.d"
  syncdir $profiled_src $profiled_dst

# sync tools dir
  linux_tools_src="$HOME/git/space/linux_env/tools"
  linux_tools_dst="$HOME/bin/"
  mkdir -p $linux_tools_dst
  syncdir $linux_tools_src $linux_tools_dst

# sync .bash_profile
  bash_src="$HOME/git/space/linux_env/profile.d/.bash_profile"
  bash_dst="$HOME/.bash_profile"
  syncfile $bash_src $bash_dst

# sync .screenrc
  screen_src="$HOME/git/space/linux_env/.screenrc"
  screen_dst="$HOME/.screenrc"
  syncfile $screen_src $screen_dst

# sync .vimrc
  vim_src="$HOME/git/space/linux_env/.vimrc"
  vim_dst="$HOME/.vimrc"
  syncfile $vim_src $vim_dst

# sync .tmux.conf
  tmux_src="$HOME/git/space/linux_env/.tmux.conf"
  tmux_dst="$HOME/.tmux.conf"
  syncfile $tmux_src $tmux_dst
}

function timesync() {
  LEN=3600
  CDATE=`date +%s`
  DEBUG=0

  if [[ -e "$HOME/.lastenvsync" ]]
  then
    ODATE=`cat $HOME/.lastenvsync`
    DIFF=$(( $CDATE - $ODATE ))
    if [[ $DIFF -gt $LEN ]]
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

function resetsync() {
 SYNCFILE="$HOME/.lastenvsync"
 if [[ -e "$SYNCFILE" ]]; then
   echo "Removing $SYNCFILE"
   rm $SYNCFILE
 fi
 echo "Removing old profile"
 syncfile $HOME/git/space/linux_env/profile.d/.bash_profile $HOME/.bash_profile
 echo "Setting new profile"
 source $HOME/git/space/linux_env/profile.d/.bash_profile
}

function goprofile() {
  vim $HOME/git/space/linux_env/profile.d/.bash_profile
}

function goenv() {
  cd $HOME/git/space/linux_env/profile.d/
}

export goprofile

export dot undot
################################ END FUNCTIONS
# grab github tools
bootstrap
# sync only by time
timesync
# check for local/alt profiles
altprofiles
###################
cd $HOME
export EDITOR=`which vim`
