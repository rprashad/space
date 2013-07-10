#!/usr/bin/perl

use strict;
use Getopt::Long;
use Data::Dumper;
use File::Path qw(mkpath);
use SQL::Translator;

my ($file, $pkg_base, $db_type);
my $result = GetOptions ( "file=s"   => \$file,
			  "package=s" => \$pkg_base,
			  "dbtype=s"  => \$db_type
			);

if (!$file || !$pkg_base) {
	print "$0 - required schema file and package base (e.g.: PackageName)\n";
	exit;
}
if (!$db_type) {
	$db_type = "MySQL";
}

if ( -d "$pkg_base/Schema/Result") {
	print "Schema Result Exists!\n";
}
else {
	die "Could not create package directories!\n" unless 
		mkpath("$pkg_base/Schema/Result");
}

# parse schema file and build data structure
my $hash = process_schema_file($file);

# produce DBIx::Schema::Result::<Classes>
make_dbix_result($pkg_base, $hash);

# produce the DBIx::Schema file
make_schema_file($pkg_base, $hash);

# produce a rollup of methods that get/set table data
make_main_class($pkg_base, $hash, $db_type);

# produce the sql required to build tables
make_sql_loader($pkg_base, $db_type);

## subroutines BEGIN
sub process_schema_file {
	my $file = shift(@_);

	# format subject to change
	open(FILE, $file) or die "Could not open $file!";
	my $table_name;
	my $hash;

	while(<FILE>) {
		chomp;	
	if ($_ !~ /^#/) {
		my (@data) = split(":", $_);
		if (!$table_name) {

			# first non-empty line produces a table name based 
			# on anything matching *_id - therefore first line 
			# must contain a primary key

			($table_name, undef) = split("_", $data[0]);
		}
		if (scalar(@data) == 0) {

			# an empty line delimits table column data
			$table_name = undef;
		}
		else {
			# build dbix::schema::results column params
			if ($data[5] ne "") {
				$data[5] = "'$data[5]'";
			}
			else {
				$data[5] = "undef";
			}

			if ($data[6] == 1 ) {
				push(@{$hash->{$table_name}->{has_many}}, $data[0]);
			}
			elsif ($data[6] == 2) {
				push(@{$hash->{$table_name}->{many_to_many}}, $data[0]);
			}
			push ( @{$hash->{$table_name}}, { $data[0] =>
				{
				'data_type' => "'$data[1]'",
				'size' => $data[2],
				'is_nullable' => $data[3],
				'is_auto_increment' => $data[4],
				'default_value' => $data[5]
	        		}
                       	     }
		      	);
		}
	}
	}
	close(FILE);
	return $hash;
}

sub make_dbix_result {
	my $pkg_base = shift(@_);
	my $hash = shift(@_);

	foreach my $table (keys %{$hash}) {
		my $Table = $table;
		$Table =~ s/\b(\w)/\U$1/g;
		my $pkg = $pkg_base . "::Schema::Result::" . $Table;
		print "Building Package: $pkg\n";
		open(PM, "> $pkg_base/Schema/Result/$Table.pm") or die "Could not write to file: $Table.pm!\n";
		print PM <<EOF
package $pkg;
use base qw(DBIx::Class::Core);

__PACKAGE__->load_components();
__PACKAGE__->table('$table');
__PACKAGE__->add_columns(  
EOF
;
	my $pkey;
	my @fkey;
	foreach my $href (@{$hash->{$table}}) {
		foreach my $col (keys %{$href}) {
               		if ($col =~ /(\w+)_id/) {
                       		my $key = $1;
                       		if ($key eq $table) {
                               		$pkey = $col;
                       		}
                       		else {
                               		push(@fkey, $col);
                       		}
               		}
               		print PM "\t\t'$col' => { \n";
			foreach my $key (keys %{$href->{$col}}) {
				print PM "\t\t\t'$key' => $href->{$col}->{$key},\n";
			}
		}
		print PM "\t\t},\n";
	}
	print PM " );\n";	
	print PM "__PACKAGE__->set_primary_key( qw($pkey) );\n";
	foreach my $fk (@fkey) {
		my ($FTable, undef) = split("_", $fk);
		$FTable =~ s/\b(\w)/\U$1/g;
		print PM "__PACKAGE__->belongs_to( '$fk' => '$pkg_base" . "::Schema::Result::" . "$FTable' );\n";

		# if (defined($hash->{$table}->{hash_many}) and grep($fk eq $_, @{$hash->{$table}->{has_many}})) {
		# print PM "__PACKAGE__->has_many( '$fk' => '$pkg_base" . "::Schema::Result::" . "$FTable' );\n";
		# }
	}

	print PM "1;\n";
	close(PM);
	}
}

sub make_schema_file{
	my $pkg_base = shift(@_);
	my $hash = shift(@_);
	open(FILE, "> $pkg_base/Schema.pm") or die "Could not create schema!\n";
	print FILE "package $pkg_base" . "::" . "Schema;\n";
	print FILE <<EOF
use base qw(DBIx::Class::Schema);

__PACKAGE__->load_namespaces;

EOF
;
	foreach my $table (keys %{$hash}) {
		$table =~ s/\b(\w)/\U$1/g;
		print FILE "__PACKAGE__->register_class('$table', '$pkg_base" . "::" . "Schema" . "::Result::" . "$table');\n";
	}
	print FILE "1;\n";
	close(FILE);
}

sub make_sql_loader{
  my $pkg_base = shift(@_);
  my $db_type = shift(@_);

  my $dyn_lib = $pkg_base . "::Schema";
  eval("use $dyn_lib;");
  my $schema = eval("$dyn_lib->connect();");

  my $translator           =  SQL::Translator->new(
      show_warnings        => 1,
      validate             => 1,
      debug		   => 1,
      parser_args          => {
         'DBIx::Schema'    => $schema,
                              },
      producer_args   => {
          'prefix'         => '$pkg_base::Schema',
                         },
  );

  $translator->parser('SQL::Translator::Parser::DBIx::Class');
  my $producer_type = "SQL::Translator::Producer::" . $db_type; 
  $translator->producer($producer_type);

  my $output = $translator->translate() or die
          "Could not generate SQL:" . $translator->error;

  open(FILE, ">$pkg_base/$pkg_base.sql") or die "Could not create SQL file!\n";
  print FILE $output;
  close FILE;

  print "\n$db_type Schema Loader File Created: $pkg_base/$pkg_base.sql\n\n";

  if ($db_type eq "MySQL") {
  	print "Run the following to delete/create a new schema:\n";
  	print "mysqladmin -uroot -p delete $pkg_base\n";
  	print "mysqladmin -uroot -p create $pkg_base\n";
  	print "mysql -uroot -p $pkg_base < $pkg_base/$pkg_base.sql\n";
   }
}

sub make_main_class{
  my $pkg_base = shift(@_);
  my $hash = shift(@_);
  my $db_type = shift(@_);
  my $subs;

  open(FILE, "> $pkg_base.pm") or die "Could not write $pkg_base.pm!\n";
  print FILE <<EOF
package $pkg_base;
use $pkg_base\:\:Schema;
use Exporter;
our \@ISA = qw(Exporter);
our \@EXPORT = qw (\$TABLES); 

EOF
;

	print FILE "our \$TABLES = {\n";
	foreach my $table (keys %{$hash}) {
		print FILE "\t'$table' => {\n";
		my $Table = $table;
		$Table =~ s/\b(\w)/\U$1/g;
		$subs->{ "create_" . $table } = $Table;
		$subs->{ "update_" . $table } = $Table;
		$subs->{ "delete_" . $table } = $Table;
		$subs->{ "find_" . $table } = $Table;
			foreach my $href (@{$hash->{$table}}) {
				foreach my $col (keys %{$href}) {
					print FILE "\t\t '$col' => " . $href->{$col}->{is_nullable} . ",\n";	
				}
			}
		 print FILE  "\t},\n\n";
	}
	print FILE "};\n";
	my $db = lc($db_type);
	print FILE <<EOF
sub new{
	my \$class = shift;
	my \$self = { };
	\$self->{dbh} = $pkg_base\:\:Schema->connect("dbi:$db:$pkg_base", 'root', 'password') or die 
		"Could not connect to database, please ensure your user and password are setup correctly in $pkg_base.pm!\n";
	
	bless(\$self, \$class);
	return \$self;
}

EOF
;

	foreach my $key (sort {$a cmp $b} keys %{$subs}) {

		print FILE "\n\nsub $key {\n";
		print FILE "\tmy \$self = shift;\n";
		print FILE "\tmy \$data = shift;\n";
		if ($key =~ /^create/) {	
			print FILE "\tmy \$rs = \$self->{dbh}->resultset('$subs->{$key}')->new(\$data);\n";
			print FILE "\t\$rs->insert;\n";
			print FILE "\treturn \$rs->in_storage;\n";
		}
		elsif ($key =~ /^update/) {
			my $table_id = lc($subs->{$key});
			$table_id .= "_id";
			print FILE "my \$row = \$self->{dbh}->resultset('$subs->{$key}')->find({'$table_id' => \$data->{'$table_id'} } );\n";
			print FILE "\t return \$row->update(\$data);\n";
		}
		elsif ($key =~ /^delete/) {
			print FILE "\t if (!defined(\$data)) { " .
			"\t\t warn \"Cannot have null dataset on this method\n\" and return undef; }\n";
			print FILE "\t return \$self->{dbh}->resultset('$subs->{$key}')->search(\$data)->delete();\n";
		}
		elsif ($key =~ /^find/) {
			print FILE "\tmy \$rs = \$self->{dbh}->resultset('$subs->{$key}')->find(\$data);\n";
			print FILE "\tif (\$rs) { return \$rs->get_inflated_columns; }\n";
		}
		print FILE "}\n";
	}
print FILE "1;\n";
close FILE;

print "Built Setter/Getter Table Class: $pkg_base.pm\n";
}
