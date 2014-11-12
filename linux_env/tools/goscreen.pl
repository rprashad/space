#!/usr/bin/env perl

# look for Attached and Detached screen sessions
my @screens = split(/\n/, `screen  -ls | grep 'tached'`);

# loop through list and prompt to attach or create a new screen unless
# TERM=screen :)
#
if (scalar(@screens) > 0) {
  for ($x=0; $x<= $#screens; $x++) {
    my $y = $x+1;
    print "$y) $screens[$x]\n";
  }

  if ($ENV{'TERM'} ne 'screen') {
    print "(New=n, Existing=#): ";
    my $choice = <STDIN>; chomp($choice);
    if ($choice =~ /n/i) {
      print "session name: ";
      $name = <STDIN>; chomp($name);
      `screen -S $name`;
    }
    else {
      if ($choice =~ /\d/) {
        my $session = (split(/\s+/, $screens[$choice - 1]))[1];
        if ($screens[$choice - 1] =~ /Detached/) {
          print "Reattaching Screen: $session ($choice)\n";
          `screen -r $session`;
        }
        elsif ($screens[$choice -1] =~ /Multi/) {
          print "Sharing session: $session ($choice)\n";
         `screen -x $session`;
        }
        else {
          print "Stealing session: $session\n";
          `screen -dRR $session`;
        }
      }
    }
  }
}
