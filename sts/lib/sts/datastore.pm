use strict;
use warnings;

package sts::datastore;
use version; our $VERSION = '0.1.1';
use FindBin qw($Bin);
use lib "$Bin";
use Neo4j::Bolt;

# wrap main function call for running as modulino
run(@ARGV) unless (caller);
#__PACKAGE__->run(@ARGV) unless caller();


sub run {
    my (@ARGV) = @_;

    connect_to_mdb();

    print "Hello world\n";
}





sub connect_to_mdb {
  my ($self) = @_;


  my $neo4j_user = $ENV{NEO4J_MDB_USER};
  my $neo4j_pass = $ENV{NEO4J_MDB_PASS};
  my $default_url = 'bolt://'.$neo4j_user.':'.$neo4j_pass.'@54.91.213.206:7687';
  print "url is $default_url\n";
  my $NEO4J_URL = $ENV{NEO4J_URL} // $default_url;



  my $mdbh = Neo4j::Bolt->connect($NEO4J_URL);
  my $conn = $mdbh->connected;
  die "No connection to neo4j: ".$mdbh->errmsg unless $conn;

  return $conn;
}

1;

__END__

=head1 NAME

sts::datastore - A simple script to demonstrate deploying

=cut
