PATH=$PATH:$HOME/bin:$HOME/bin/tools:/usr/bin:/usr/sbin:/usr/local/bin:/bin:/sbin
export PERL5LIB=/data/ops/lib/:$HOME/space/perl
export PYTHONPATH=$HOME/space/python
GITBIN=$HOME/git/space/linux_env/tools

# sync tools
$GITBIN/linuxenv_sync.sh

# display existing screen sessions
$GITBIN/goscreen.pl
