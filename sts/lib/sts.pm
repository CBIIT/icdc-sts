package sts;
use version; our $VERSION = '0.2.0';
use Mojo::Base 'Mojolicious';
use DBI;
use Neo4j::Bolt;
use sts::CypherQueries qw( %queries );
use sts::helpers qw( setup_sanitizer );
use strict;

# This method will run once at server start
sub startup {
    my $self = shift;

    # Load configuration from hash returned by config file
    my $config = $self->plugin('Config');

    # Configure the application
    $self->secrets( $config->{secrets} );

    # Router
    my $r = $self->routes;

    # Normal route to controller
    $r->get('/')->to('actions#ack');
    $r->get('/healthcheck')->to('actions#healthcheck');

    $r->get('/node/list')->to('actions#list_nodes');
    $r->get('/node/all')->to('actions#all_node_details');
    $r->get('/node/:node_id')->to('actions#node_details');
    $r->get('/properties')->to('actions#properties');
    $r->get('/value_sets')->to('actions#value_sets');
    $r->get('/value_sets/:value_set_id')->to('actions#value_set');
    $r->get('/terms')->to('actions#terms');
    $r->get('/terms/:term')->to('actions#term');

    # initial simple sanitization helper (sanitize_input)
    setup_sanitizer($self);

    # setup db interface
    setup_mdb_interface($self);
    $self->log->debug("Ready");

}


sub setup_mdb_interface {
    my ($self) = @_;

    # TODO: better, explicit error if these are empty
    # Grab AWS credentials from environment
    my $neo4j_user = $ENV{NEO4J_MDB_USER};
    my $neo4j_pass = $ENV{NEO4J_MDB_PASS};

    # Construct MDB access url
    # e.g. bolt://user:pass@54.91.213.206:7687'
    my $mdb_url =
        'bolt://'
      . $neo4j_user . ':'
      . $neo4j_pass . '@'
      . $self->config->{mdb_ip};
    my $NEO4J_URL = $ENV{NEO4J_URL} // $mdb_url;

    my $mdbh = Neo4j::Bolt->connect($NEO4J_URL);
    my $conn = $mdbh->connected;
    die "No connection to neo4j: " . $mdbh->errmsg unless $conn;
 
    # construct anonymouns subs for each queries as needed in routes above
    while ((my $queryname, my $cypherquery) = each (%queries)) { 
        eval "\$self->helper( ${queryname}_sref => sub { 
            return sub {
                my (\$param_href) = \@_;
                \$mdbh->run_query( \$cypherquery, \$param_href ) 
            }
        } )";
    }
}

1;
