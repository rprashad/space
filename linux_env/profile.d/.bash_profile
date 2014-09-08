### Rajendra Prashad 

PATH=$PATH:$HOME/bin:$HOME/bin/tools:/usr/bin:/usr/sbin:/usr/local/bin:/bin:/sbin
export PERL5LIB=/data/ops/lib/:$HOME/space/perl
export PYTHONPATH=$HOME/space/python
alias jsoncheck='python -mjson.tool'
declare -a fgcolor
declare -a bgcolor
fgchoice=""
bgchoice=""
fgcolor=( [black]=30 [red]=31 [green]=32 [yellow]=33 [blue]=34 [magenta]=35 [cyan]=36 [white]=37 )
bgcolor=( [black]=40 [red]=41 [green]=42 [yellow]=43 [blue]=44 [magenta]=45 [cyan]=46 [grey]=47 )
defbg=white
deffg=black

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


function setcolor() {
  fgchoice=$1
  bgchoice=$2
  osx=`uname | grep -i darwin | wc -l`

  if [[ $osx -eq 1 ]]; then
    echo "not setting colors"
    return
  fi 


  if [[ -z $fgchoice ]]; then
    fgchoice=$deffg
  else if [[ -z ${fgcolor[$fgchoice]} ]]; then
    echo "fg choice '$fgchoice' - does not exist, setting default: $deffg"
    fgchoice=$deffg
  fi
  fi

  if [[ -z $bgchoice ]]; then
    bgchoice=$defbg
  else if [[ -z ${bgcolor[$bgchoice]} ]]; then
    echo "bg choice '$bgchoice' - does not exist, setting default: $defbg"
    bgchoice=$defbg
  fi
  fi

   echo "BG: $bgchoice: FG: $fgchoice"

  case "$TERM" in
  linux|screen|xterm*|rxvt*)
       # PS1="\[\033[${fgcolor[${fgchoice}]}m\][\$(date +%H%M)][\u@\h:\w]$ "
       PS1="\[\033[${fgcolor[${fgchoice}]}m\033[${bgcolor[${bgchoice}]}m\][\$(date +%mm%dd)][\u@\h:\w]$ "
       
      ;;
  *)
      ;;
  esac
} # setcolor

function setps1() {

  case "$TERM" in
  linux|screen|xterm*|rxvt*)
       # PS1="[\$(date +%H%M)][\u@\h:\w]$ "
       PS1='[\u@\h \W$(__git_ps1 " (%s)")]\$ '
      ;;
  *)
      ;;
  esac

}

function screen_sessions() {
  screens=`which screen | grep -iv No`
  if [[ ! -z "$screens" ]]; then
    $HOME/git/space/linux_env/tools/goscreen.pl
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

function syncfile() {
  SYNC_SOURCE=$1
  SYNC_DEST=$2

  echo "Syncing File $SYNC_SOURCE -> $SYNC_DEST"
  rsync --suffix=.bak $SYNC_SOURCE $SYNC_DEST
} # syncfile

function syncdir () {
  SOURCE=$1
  DEST=$2

  echo "Syncing Directory $SYNC_SOURCE -> $SYNC_DEST"
  rsync -ap $SYNC_SOURCE $SYNC_DEST
} # syncdir

function allcolors() {
  # stolen shamelessly from 
  # http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/x329.html

  T='gYw'   # The test text
  echo -e "\n                 40m     41m     42m     43m\
       44m     45m     46m     47m";

  for FGs in '    m' '   1m' '  30m' '1;30m' '  31m' '1;31m' '  32m' \
             '1;32m' '  33m' '1;33m' '  34m' '1;34m' '  35m' '1;35m' \
             '  36m' '1;36m' '  37m' '1;37m';
    do FG=${FGs// /}
    echo -en " $FGs \033[$FG  $T  "
    for BG in 40m 41m 42m 43m 44m 45m 46m 47m;
      do echo -en "$EINS \033[$FG\033[$BG  $T  \033[0m";
    done
    echo;
  done
  echo
} # allcolors

function syncall() {
# sync tools dir
  linux_tools_src="$HOME/git/space/linux_env/tools"
  linux_tools_dst="$HOME/bin/"
  mkdir -p $linux_tools_dst
  syncdir $linux_tools_src $linux_tools_dst

# sync .bash_profile
  bash_src="$HOME/git/space/linux_env/profile.d/.bash_profile"
  bash_dst="$HOME/.bash_profile"
  syncfile $bash_src $bash_dst

# sync .profile.d files
  # git prompt
  githelper_src="$HOME/git/space/linux_env/profile.d/git-prompt.sh"
  githelper_dst="$HOME/.profile.d"
  syncfile $githelper_src $githelper_dst

# sync .screenrc
  screen_src="$HOME/git/space/linux_env/.screenrc"
  screen_dst="$HOME/.screenrc"
  syncfile $screen_src $screen_dst

# sync .vimrc
  vim_src="$HOME/git/space/linux_env/.vimrc"
  vim_dst="$HOME/.vimrc"
  syncfile $vim_src $vim_dst

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

export dot undot
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
###################
cd $HOME
export EDITOR=`which vim`
