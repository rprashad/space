#!/usr/bin/perl


my $num = $ARGV[0] || 10;
my $x = 0;
my @a;
for ($x; $x <= $num; $x++) {

	my $val;
	if ($x ==0 || $x == 1) {
		push(@a, $x);
	}

	$a[$x] = $a[$x - 1] + $a[$x - 2];
	print $a[$x] . "\n";
}
