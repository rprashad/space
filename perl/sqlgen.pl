#!/usr/bin/perl


use Properties::Schema;
use SQL::Translator;
  
  my $schema = Properties::Schema->connect('dbi:mysql:properties root Million$');
  
  my $translator           =  SQL::Translator->new( 
      debug                => $debug          ||  0,
      trace                => $trace          ||  0,
      no_comments          => $no_comments    ||  0,
      show_warnings        => $show_warnings  ||  0,
      add_drop_table       => $add_drop_table ||  0,
      validate             => $validate       ||  0,
      parser_args          => {
         'DBIx::Schema'    => $schema,
                              },
      producer_args   => {
          'prefix'         => 'Properties::Schema',
                         },
  );
  
  $translator->parser('SQL::Translator::Parser::DBIx::Class');
  $translator->producer('SQL::Translator::Producer::DBIx::Class::File');
  
  my $output = $translator->translate(@args) or die
          "Error: " . $translator->error;
  
  print $output;
