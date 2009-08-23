#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'LinkSeeker' );
}

diag( "Testing LinkSeeker $LinkSeeker::VERSION, Perl $], $^X" );
