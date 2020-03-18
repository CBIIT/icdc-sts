use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

use lib 'lib';

BEGIN {
    use_ok( 'sts' ) || print "Bail out!\n";
}

diag( "Testing sts $sts::VERSION, Perl $], $^X" );

## simple check for ability to load sts module
