#!perl
use strict;
use warnings;

use FindBin qw($Bin);
use Test::More skip_all => 'work in progress';
use Test::PerlTidy;

# run suite of PerlTidy tests
run_tests(
    path       => "$Bin/../",
    perltidyrc => "$Bin/.perltidyrc",
    exclude    => [ qr{\.t$}, qr{File}, qr{Getopt}, qr{JSON}, qr{Test} ],
);

