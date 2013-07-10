#!/usr/bin/perl


use SQL::Translator;
use Getopt::Long;
use Property::Schema;

my ($pkg_base, $rebuild, $create, $delete, $load,$password);
my $result = GetOptions ( 
                          "package=s" => \$pkg_base,
                          "rebuild" => \$rebuild,
                          "create" => \$create,
                          "delete" => \$delete,
                          "load"  => \$load,
                          "password=s" => \$password );

        my $schema = Property::Schema->connect('dbi:mysql:properties root Million$');
  
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
          'prefix'         => '$pkg_base::Schema',
                         },
  );
  
  $translator->parser('SQL::Translator::Parser::DBIx::Class');
  # $translator->producer('SQL::Translator::Producer::DBIx::Class::File');
  $translator->producer('SQL::Translator::Producer::MySQL');
  
  my $output = $translator->translate(@args) or die
          "Error: " . $translator->error;
  
  open(FILE, ">$pkg_base/$pkg_base.sql") or die "Could not create SQL file!\n";
  print FILE $output;
  close FILE;

