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
}


sub connect_to_mdb {

  # Grab AWS credentials from environment
  my $neo4j_user = $ENV{NEO4J_MDB_USER};
  my $neo4j_pass = $ENV{NEO4J_MDB_PASS};

  # Construct MDB access url
  ## TODO remove hard-coded values to config file
  my $default_url = 'bolt://'.$neo4j_user.':'.$neo4j_pass.'@54.91.213.206:7687';
  my $NEO4J_URL = $ENV{NEO4J_URL} // $default_url;

  my $mdbh = Neo4j::Bolt->connect($NEO4J_URL);
  my $conn = $mdbh->connected;
  die "No connection to neo4j: ".$mdbh->errmsg unless $conn;

  return $mdbh;
}

sub query_mdb {
    ## TODO document result structure (array of hashes)
    my ($mdbh, $query) = @_;
    my @result;

    ## do actual query
    my $stream = $mdbh->run_query( $query ,{} ); 
  
    ## TODO error handling

    ## get field header names
    my @names = $stream->field_names;

    ## get data and handle empty/null values
    ## TODO handle empty fields correctly
    my @data = ();
    while ( my @row = $stream->fetch_next ) {
        my @cleaned = ();
        foreach my $j (@row){
                $j = $j || 'NULL';
                push @cleaned, $j;
        }
        push @data, \@cleaned;
    }

    ## zip field header names and data into hash
    for my $l (@data) {
        ## option 1
        #my %h = zip @names, @$l;
        
	## option 2
        my %h;
        @h{@names} = @$l;
        
	push @result, \%h;
    }

    return @result;
}





1;

__END__

=head1 NAME

sts::datastore - A simple module for accessing datastores (sqlite, neo4j mdb)

=cut
