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

use strict;
package Container::INI;

sub new {
  my $class = $_[0];
  my $self = { 'file' => $_[1] };
  bless($self,$class);
  $self->source_config;
  return $self;
}
 
sub source_config {
  my $self = $_[0];

  open(CFG, "< $self->{file}" ) or die __PACKAGE__ . " Error reading ini: $self->{file}\n";
  my ($module, $hpoint, $key, $value, $evalue, $continue, $quoted);
  $module = {};
  while(<CFG>) {
   chomp($_);
   # ignore lines that begin with '#' or ';' or whitespace
   if ($_ !~ /^\s*?(?:#|;)/) {
     # Find context/header
     	if ($_ =~ /\[\s*(.*)\s*\]/g) {
		# this allows for unlimited context separators '::' to be present in the header
		# [this::is::valid] = $this->{is}->{valid}
		my $conf = $self->build_conf([ split /[:]{2}/, $1 || ( $1 ) ], undef);
		$module = $self->merge_conf($module, $conf);
		$hpoint = $self->build_ref_point($module, $conf);
       } # end context/header
		
	# process key/value pairs
        else {
          # line continuation code
          if (!$continue and !$quoted) {
            ($key, $value) = split("=",$_,2);
            $key =~ s/\s+//g;
          }
          else {
           $value = $_;
          }

          # found line continuation char \
          if ($value =~ /(.*)\s*?\\\s*?$/) {
            $continue += 1;
          }

          # found quoted text
          elsif ($value =~ /"/ && $value !~ /"[^"]+"/) {
            $quoted++;
          }

          # single line entity - build/merge
          if (!$continue and !$quoted) {
            my $conf = $self->build_conf([ split /\./, $key ], $value);
            $$hpoint = $self->merge_conf($$hpoint, $conf);
          }

          # found line continuation char \      
          elsif ($value =~ /(.*)?\s*?\\\s*?$/) {
            $value = $1 . "\n";
            $evalue .= $value;
          }
          # found a quote
          elsif ($quoted == 1) {
            $evalue .= "$value\n";
          }
          # we've reached the end of our multi-line value
          else {
            $evalue .= $value;
            my $conf = $self->build_conf([ split /\./, $key ], $evalue);
            $$hpoint = $self->merge_conf($$hpoint, $conf);
            $continue = $evalue = $quoted = undef;
          }
       } # end key/val procesing
  } # end syntax check
 } # end while

  close(CFG);
  $self->{conf} = $module;
  return $self->{conf};
}

sub get_config() {
  return $_[0]->{conf};
}

# merges two hash references 
sub merge_conf {
  my ($self, $dst, $src) = @_,;
  my $return =  { %{ $dst || {} } };
  
  foreach my $key (keys %{$src}) {
    my $ref = ref($src->{$key});
    if ($ref eq 'HASH') {
      if( defined $return->{$key} && !ref( $return->{$key} ) ) {
        warn __PACKAGE__ . " found previous assignment for '$key', reassigning";
      }
      $return->{$key} = $self->merge_conf($return->{$key}, $src->{$key})
    } 
    elsif ($ref eq 'ARRAY') {
      $return->{$key} = []; 
      @{$return->{$key}} = @{$src->{$key}};
    } 
    else {
      if( defined $return->{$key} && ref( $return->{$key} ) ){
         warn __PACKAGE__ . " found previous assignment for '$key', reassigning";
      }
      $return->{$key} = $src->{$key};
    }
  }
return $return;

}

# converts an array in index order to a nested hash if applicable
sub build_conf {
  my ($self, $aref, $val)  = @_;
  my $element = shift(@{$aref});
  my $hash = {};
  if ($element) {
    $hash->{$element} = $self->build_conf($aref, $val);
    return $hash;
  }

    my (@a) = map { s/\\,/,/g; s/(?<!\\)"//g; $_ } split(/\s*(?<!\\),\s*/,$val);
    (scalar(@a) > 1) ? return \@a : return $a[0];
}

# return a ref to what would be or is the value
sub build_ref_point {
  my ($self, $module, $conf)  = @_;
  foreach my $key (keys %{$conf}) {	
    if (ref($module->{$key})) {
      return $self->build_ref_point($module->{$key}, $conf->{$key});
    }
    else {
	if (!defined($module->{$key})) {
		$module->{$key} = undef;
	}
	return \$module->{$key};
	}
  }
}

1;
