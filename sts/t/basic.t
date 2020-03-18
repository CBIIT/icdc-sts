use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new('sts');
$t->get_ok('/')->status_is(200)->content_like(qr/\"service\"\:\"STS\",\"version\":/i);

done_testing();


=pod
 
=head1 DESCRIPTION

Makes basic query and looks to see that the basic identifier string is returned.

=cut
