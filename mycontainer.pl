#!/usr/bin/perl

use Container::INI;
use Data::Dumper;

my $me = Container::INI->new("me.ini") or die "Could not find file!\n";
my $you = new Container::INI("you.ini") or die "Could not find file!\n";

print Dumper $me->get_config;
print Dumper $you->get_config;
