#!/usr/bin/perl

use Container::INI;
use Data::Dumper;

print Dumper [  
	Container::INI->new("example1.ini")->get_config ,
        Container::INI->new("example2.ini")->get_config 
      ];
