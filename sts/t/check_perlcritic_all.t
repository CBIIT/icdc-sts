#!perl
use strict;
use warnings;

use FindBin qw($Bin);
use Test::Perl::Critic (-severity => 5, -verbose => 9);

my $lib_dir = "$Bin/../lib/sts";
my $test_dir = "$Bin/../t";
all_critic_ok(($lib_dir, $test_dir));
