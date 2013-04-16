#    copyright 2013 - Rajendra Prashad nprashad@gmail.com
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

#!/usr/bin/perl
#
package Container::INI;
use strict;

sub new() {
	my $class = shift;
	my $config = shift;
	my $self = {};
	bless($self,$class);
	$self->source_config($config);
	return $self;
} 
sub source_config($) {
	my $self = shift;
	my $file = shift;
	my $cwd = `pwd`; chomp($cwd);

	# check current working directory
	if ( -e $cwd . "/" . $file) {
		$file = $cwd . "/" . $file;
	}
	
    $self->{config} = $file;
	
	
        open(CFG, "< $file") or 
		die __PACKAGE__ . "Error reading ini: $file\n";

	my ($module, $hpoint, $key, $value, $evalue, $continue, $quoted);
	while(<CFG>) {
		chomp;
		# ignore lines that begin with '#' or ';' or whitespace

                if ($_ !~ /^\s*?#/ && $_ ne "" && $_ !~ /^;/ or $quoted > 0) {
			# LOOK FOR HEADER INFO
               		if ($_ =~ /^\s*\[\s*(\w+)?:?:?(\w+)?\s*\]/) {
				my $mod = $1;
				my $options = $2;
				$hpoint = undef;
				if (!defined($module->{$mod})) {
					$module->{$mod} = undef;
					$hpoint = \$module->{$mod};
				}
				if ($options) {
					$hpoint = \$module->{$mod}->{$options};
				}
				else {
					# structures may/will exist
					$hpoint = \$module->{$mod};
				}
			}
		
			# OTHERWISE PROCESS KEY/VAL PAIRS
			else {
				# line continuation code
				if (!$continue and !$quoted) {
					($key, $value) = split("=",$_,2);
					$key =~ s/\s+//g;
					# $key = $1;
				}
				else {
					$value = $_;
				}
				
				if ($value =~ /(.*)\s*?\\\s*?$/) {
					# print "Found line continuation: $value\n";
					$continue += 1;
				}
				elsif ($value =~ /"/ && $value !~ /"[^"]+"/) {
					$quoted++;
					# $value =~ s/^\s*//g;
				}

				if (!$continue and !$quoted) {
					my $conf = $self->build_conf($key, $value);
					$$hpoint = $self->merge_conf($$hpoint, $conf);
				}
				elsif ($value =~ /(.*)?\s*?\\\s*?$/) {
						$value = $1 . "\n";
						$evalue .= $value;
				}
				elsif ($quoted == 1) {
						$evalue .= "$value\n";
				}
				else {
						$evalue .= $value;
						my $conf = $self->build_conf($key, $evalue);
						$$hpoint = $self->merge_conf($$hpoint, $conf);
						$continue = undef;
						$evalue = undef;
						$quoted = undef;
				}
			}
		}
	}

	close(CFG);
	$self->{conf} = $module;
	return \$self->{conf};
}

sub get_config() {
	my $self = shift;
	return $self->{conf};
}

sub merge_conf() {
=pod

=over 4

=item merge_conf (private)

This doesn't actually modify the first hash unless you have references within an arrayref.

B<THIS IS NOT A DEEP COPY> 

I<Arguements>: hashref to be default values, hashref of data to write over in the first hashref

I<Returns>: hashref of resulting data (their may be references to the first hashref)

=back

=cut

my $self = shift;
my $dst = shift;
my $src = shift;

my $return =  { %{ $dst || {} } }; # shallow copy (if undef will give an new empty hash

foreach my $key (keys %{$src}) {
    my $ref = ref($src->{$key});
    if ($ref eq 'HASH') {
        if( defined $return->{$key} && !ref( $return->{$key} ) ){
            die __PACKAGE__ . "detected previous scalar assignment for key '$key', cannot reassign as hashref";
        }
        $return->{$key} = $self->merge_conf($return->{$key}, $src->{$key})

    } elsif ($ref eq 'ARRAY') {
        $return->{$key} = []; # initialize incase it's not an array from the globals
        @{$return->{$key}} = @{$src->{$key}};

    } else {
        if( defined $return->{$key} && ref( $return->{$key} ) ){
            die __PACKAGE__ . "detected previous hashref assignment for key '$key', cannot reassign as scalar";
        }
        $return->{$key} = $src->{$key};
    }
}
return $return;

} ################################################## END merge_conf


sub build_conf() {
	my $self = shift;
	my $key = shift;
	my $value = shift;
	my $conf = $self->is_dot_notation($key, $value);
	return $conf;
}

sub is_dot_notation() {

	my $self = shift;
	my $key = shift;
	my $value = shift;
	my @dots = split(/\./, $key);
	return $self->recursive_hash(\@dots, $value);
}

sub recursive_hash() {
	my $self = shift;
	my @array = @{shift(@_)};
	my $val = shift(@_);
	my $e = shift(@array);
	my $hash;
	if ($e) {
		$hash->{$e} = $self->recursive_hash(\@array, $val);
		return $hash;
	}

	if (substr($val, 0, 1) eq "\"") {
		$val =~ s/"//g;
		return $val;
	}
	my (@a) = map { s/\\,/,/g; $_ } split(/\s*(?<!\\),\s*/,$val);
	(scalar(@a) > 1) ? return \@a : return $a[0];
}

1;
